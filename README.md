# EntecPro
Simple commandline DMX Console written in Powershell 

(For the Entex USB Pro Mk2)

# Commands
set <channel> <value>
fade <channel> <from> <to> <ms>
show <channel>
blackout
exit

cue save <name>        # Save current universe as a cue
cue list               # List stored cues
cue load <name>        # Instantly recall a cue
cue fade <name> <ms>   # Fade current state to cue
cue delete <name>      # Remove cue


Cues are stored in:

cues.json


in the script directory.

#example

dmx> set 1 255
dmx> fade 1 255 0 2000
dmx> set 5 128
dmx> show 5
Channel 5 = 128
dmx> blackout
dmx> exit
