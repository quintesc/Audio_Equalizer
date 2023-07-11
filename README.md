# Audio Equalizer

This is the semester-wide team project for ECE 551, in which as a team we had to implement in verilog the digital circuit for an audio equalizer. We have an amazing professor who actually built the circuit using a DE0-Nano fpga, speakers, sliders, and an RN52 bluetooth module so we could test our design.


A basic system overview: We get audio input from the RN52 bluetooth module. Then there are 6 sliders: 5 of them control different band pass filters, and the other one is an overall volume slider. The sliders are used to filter the music we get from bluetooth. Finally we output the filtered sound to a pair of speakers.

Top level module: `Equalizer.sv`
  
This was a team project where I got the chance to meet and work with these three amazing people:
Jo Alshwaish (alshwaish@wisc.edu)
Reem Al Mazroa (almazroa@wisc.edu)
Lujain Al Jumah (laljumah@wisc.edu)
