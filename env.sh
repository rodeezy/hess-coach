# Local, project-scoped Ruby toolchain. Source before running ruby/rails/bundle.
# Does NOT change machine defaults; only affects the current shell/command.
export rvm_silence_path_mismatch_check_flag=1
export GEM_HOME="$HOME/.rvm/gems/ruby-4.0.7"
export GEM_PATH="$HOME/.rvm/gems/ruby-4.0.7:$HOME/.rvm/gems/ruby-4.0.7@global"
export PATH="$HOME/.rvm/gems/ruby-4.0.7/bin:$HOME/.rvm/gems/ruby-4.0.7@global/bin:$HOME/.rvm/rubies/ruby-4.0.7/bin:$PATH"
