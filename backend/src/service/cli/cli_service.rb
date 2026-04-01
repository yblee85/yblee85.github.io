require "open3"

module Cli
  class Service
    Result = Struct.new(:ok, :exit_code, :stdout, :stderr)

    def run(*command, chdir: nil, env: {})
      cmd = command.flatten.compact.map(&:to_s)
      raise ArgumentError, "command is required" if cmd.empty?

      opts = {}
      opts[:chdir] = chdir unless chdir.nil?

      stdout, stderr, status = Open3.capture3(env, *cmd, **opts)
      Result.new(
        ok: status.success?,
        exit_code: status.exitstatus,
        stdout: stdout.to_s,
        stderr: stderr.to_s
      )
    end
  end
end
