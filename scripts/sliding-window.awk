# This is a sliding window by record separator,
# But I also might need one by byte?
# At least I can make a line-wise and word-wise sliding window.
# I could actually probably make it bytewise by making the RS=.

# This awk program keeps a memory of the last window_size records.
# and steps forwards 2 records at a time.
BEGIN {
  # Initialize the memory with the first window_size records.
  for (i=1; i<=window_size; i++) {
    memory[i] = $i
  }
}

{
  # Update the memory.
  for (i=1; i<=window_size; i++) {
    memory[i] = memory[i+1]
    # print "update", i, memory[i], RS
  }
  memory[window_size] = $0

  effective_nr = NR - window_size

  if (NR >= window_size && (effective_nr % step == 0)) {
      s = ""
      for (i=1; i<window_size; i++) {
          s = s memory[i] RS
      }
      s = s memory[window_size]
      printf "(%s)", s |& cmd

      close(cmd, "to");
      $0 = "";

      brs=RS
      RS="##long read##"
      cmd |& getline $0;
      fflush(cmd);
      close(cmd);
      RS=brs
      print; system("");
  }
}