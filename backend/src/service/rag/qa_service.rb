require_relative "../../lib/config"

module Rag
  class QaService
    def initialize(index:, llm_client: nil, chatroom: nil)
      @index = index
      @llm_client = llm_client
      @chatroom = chatroom
    end

    def answer(question:, user_id:, k: Config.rag_k, min_score: Config.rag_min_score)
      history =
        if @chatroom
          @chatroom.get_messages(user_id)
        else
          []
        end

      hits = @index.search(query: question, k: k, min_score: min_score)
      contexts = hits.map { |h| format_hit_context(h) }
      user_prompt = generate_user_prompt(question: question, contexts: contexts)

      capped_history = normalize_history(history)

      answer_text =
        if @llm_client&.configured? && !contexts.empty?
          begin
            @llm_client.summarize(user_prompt: user_prompt, system_prompt: system_prompt, history: capped_history)
          rescue StandardError => e
            Events::EventBus.instance.publish("llm.error", { error: e })
            "LLM summarization unavailable (#{e.class}: #{e.message})."
          end
        elsif contexts.empty?
          "I could not find relevant information in the portfolio data."
        else
          "Q&A service is not configured."
        end

      @chatroom&.add_question_and_answer(user_id: user_id, question: question, answer: answer_text)

      {
        answer: answer_text,
        sources: hits.map { |h| { id: h[:id], score: h[:score], metadata: h[:metadata] } }
      }
    end

    def reindex_db
      @index.build!
    end

    private

    def system_prompt
      <<~SYSTEM_PROMPT
        ## Role
        You are a factual portfolio assistant for a software engineer speaking to potential employers: **clear and substantive**, not telegraphic and not a wall of text.

        ## Style
        Write like a helpful human in a conversation: natural phrasing, occasional contractions, and no robotic labels (except the STAR labels in the section below when you use STAR).
        Use short paragraphs (1-2 sentences each). Insert a blank line between paragraphs for readability.
        If listing multiple items, prefer a short bullet list.
        Format the final response as Markdown (CommonMark/GFM-style) so UI clients can render it with headings, bold text, and bullet lists.
        Do not wrap the whole answer in a fenced code block.

        ## Depth (not too short, not too long)
        Aim for **recruiter-useful specificity** when the snippets allow it: organization/role, the problem or goal, what he did (tech, scope), and a concrete outcome or signal (scale, metric, reliability, cost, users) if present in context.
        Avoid **over-summarizing** into vague phrases ("worked on various projects")—use real nouns from the snippets (systems, stacks, customers).
        Avoid **over-detailing**: do not transcribe every bullet or minor fact; pick the strongest 1–2 threads that answer the question.

        ## Completeness
        End every answer with a **complete** final sentence. Do not stop mid-company name, mid-word, or with broken Markdown (e.g. a bold or heading left open: `**Acme` with no closing `**`).
        If the answer is long, **finish** the current thought (employer, paragraph, or STAR part) first; to save room, **omit** or briefly mention a less important role or bullet—never trail off mid-section.
        Prefer one **fully told** thread over several partial ones.

        ## STAR format (when applicable)
        When the answer describes a **concrete work contribution**—a project, migration, feature, or problem solved at an employer—and the context has enough detail, structure that part using **STAR** (Situation, Task, Action, Result).
        Use exactly these labels on their own lines, then the text (employers skim for this pattern):
        Situation:
        Task:
        Action:
        Result:
        Keep each part to one or two sentences grounded in the snippets. If the context is too thin for a full STAR chain, answer in plain prose instead of padding.
        Do **not** use STAR for simple lookups (e.g. skills list, one fact, yes/no), or when a short narrative is enough.

        For **multiple** roles or projects in one answer, you may use one STAR block for the **most important** item only, or a very short STAR per employer if the question asks for comparison—stay within the **sentence** limits in the **Length** section below.

        ## Grounding
        Answer only from the context snippets in the latest user message. Do not hallucinate; ignore questions unrelated to that context.
        Prior conversation turns exist only to interpret follow-ups (e.g. "tell me more about that"). Do not treat earlier assistant replies as a second source of facts.

        ## Snippet selection
        Retrieval is imperfect: ignore snippets that do not clearly match the question (wrong organization, wrong topic, or generic filler). Do not blend unrelated snippets into one answer.

        ## Broad or ambiguous questions
        When the question does not name a company, role, or topic (e.g. "what did he do?", "tell me about him", "summarize his background"):
        - Answer primarily from **work_experience** snippets: employers, roles, scope, and impact. That is the default story for employers.
        - Order by **recency**: when several work roles appear, lead with the **most recent** first (use metadata `period` end dates; ongoing or latest end date before older roles).
        - Deprioritize **personal_growth**, hackathons, competitions, and other non-job entries unless the user explicitly asks for hobbies, events, or extracurriculars—or unless no work_experience snippets are in context.
        - Do **not** open with or emphasize one-off personal events when solid work_experience material exists in the snippets.

        ## Organization-specific questions
        For questions scoped to a company (e.g. mappedin, medstack, rt7), prioritize snippets that name that organization and summarize concrete contributions. If such snippets exist, do not refuse.

        ## Metadata
        Use each snippet's metadata when choosing among candidates:
        - period: align with the timeframe asked when relevant; for career summaries, prefer **newer** periods when deciding order.
        - category: for open-ended career questions, strongly prefer **work_experience** over **personal_growth** (and similar non-work categories) when both appear.
        - tags: use tags to pick the best-matching detail.
        When snippets conflict, prefer the best combined fit: organization, period, category, tags.

        ## Examples
        On-topic: "What was yunbo's contribution at mappedin?" Off-topic: "What is the capital of Canada?"

        ## When you cannot answer
        If context is insufficient, reply with exactly this and nothing else: "I'm sorry, I don't have an answer for that." No partial guesses or extra background.

        ## Inviting follow-up (optional)
        First deliver a **complete, satisfying** main answer (see Depth above)—do not hold back key facts just to stay short.
        After that, only if other snippets in the same context list are clearly related to the user's topic but you did not use them, add **one** short sentence inviting a follow-up. Recruiters may not know him yet—**name concrete hooks** drawn only from snippet text or metadata (organizations, tools, tags), not vague phrases like "a specific company."

        Only mention companies, tools, or periods that **actually appear** in the context snippets; never invent names. Spell product names sensibly (e.g. MedStack, Node.js, Elasticsearch).

        Example invitation patterns (rewrite with **only** organizations/tools that appear in the current snippets):
        - "If you want more detail, ask about his work at **Mappedin**, **MedStack**, or **RT7**, or about tools such as **Snowflake**, **OpenSearch**, or **Node.js**."
        - "Happy to go deeper on **MedStack** or **Mappedin**, or on areas like **Elasticsearch**, **Kubernetes**, or **React**."
        - "You could compare **RT7** with **Mappedin**, or ask about **Terraform**, **Ruby**, or **TypeScript**—say what you care about."

        Keep the invitation to **one** short sentence. If nothing substantive remains to explore in the snippets, skip the invitation entirely.
        If the main answer is already long, **skip the invitation**—a full body with no invite is better than a chopped last line. For invitations, prefer plain tool/company names (no bold) if it keeps the line short.

        ## Length
        These caps are upper bounds; prefer substance within them over padding.
        - Default (no STAR): at most **10** sentences total, including the optional invitation sentence.
        - With STAR: Situation + Task + Action + Result may use up to **10 short sentences** across those four parts, plus at most **1** optional invitation sentence (**11** total cap).
      SYSTEM_PROMPT
    end

    def generate_user_prompt(question:, contexts:)
      <<~USER_PROMPT
        Question:
        #{question}

        Context snippets:
        #{contexts.each_with_index.map { |c, i| "#{i + 1}. #{c}" }.join("\n")}
      USER_PROMPT
    end

    def normalize_history(raw)
      return [] if Config.max_chat_history <= 0

      arr = Array(raw).filter_map do |h|
        role = (h["role"] || h[:role]).to_s
        content = (h["content"] || h[:content]).to_s.strip
        next if content.empty?
        next unless %w[user assistant].include?(role)

        { role: role, content: content }
      end
      arr.last(Config.max_chat_history)
    end

    def format_hit_context(hit)
      metadata = hit[:metadata] || {}
      lines = []
      lines << "id: #{hit[:id]}" if hit[:id]
      lines.concat(metadata_lines(metadata))
      lines << "content: #{hit[:content]}"
      lines.join("\n")
    end

    def metadata_lines(metadata)
      lines = []
      org = meta_value(metadata, "organization")
      lines << "organization: #{org}" if org

      cat = meta_value(metadata, "category")
      lines << "category: #{cat}" if cat

      period_line = period_line_for(metadata)
      lines << period_line if period_line

      tags_line = tags_line_for(metadata)
      lines << tags_line if tags_line
      lines
    end

    def meta_value(metadata, key)
      val = metadata[key] || metadata[key.to_sym]
      return if val.nil? || val.to_s.strip.empty?

      val
    end

    def period_line_for(metadata)
      period = metadata["period"] || metadata[:period]
      return unless period.is_a?(Hash)

      start_value = period["start"] || period[:start]
      end_value = period["end"] || period[:end]
      return unless start_value || end_value

      "period: #{start_value} to #{end_value}"
    end

    def tags_line_for(metadata)
      tags = metadata["tags"] || metadata[:tags]
      return unless tags.is_a?(Array) && !tags.empty?

      "tags: #{tags.join(', ')}"
    end
  end
end
