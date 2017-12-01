function blaze
	set status_cmd './scripts/build_status.sh'
	if contains 'build' $argv; and test -e $status_cmd
		/usr/local/bin/bazel build --workspace_status_command=$status_cmd (string replace 'build ' '' "$argv")
	else
		/usr/local/bin/bazel $argv
	end
end
