  unless STDIN.tty?  # we are in a pipeline
    while((line = STDIN.gets))
      p line
    end
  else
  end
