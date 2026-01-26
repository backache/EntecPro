# EntecPro
Simple commandline DMX Console written in Powershell 

(For the Entex USB Pro Mk2)

When you start it you are give a "dmx> " prompt in which to write your commands

# Commands

## Direct

### Set

`set <channel> <value>` 

Immediatly change a value, for example to set Channel 1 to 255

_set 1 255_  

### fade

`fade <channel> <from> <to> <ms>`  

Example to fade Channel 1 to the value of 255 to value 0 0 over 2000 milliseconds (two seconds)

_fade 1 255 0 2000_

### Show
`show <channel>` 

example to see what value to channel is set to

_show 5_

It will then respond with 

_Channel 5 = 128_

### Blackout

`blackout` 

sets everying to zero

### exit

`exit`  

Triggers a blackout and then exits the script

## Cues

### save
`cue save <name>`        
# Save current universe as a cue

### list
`cue list`               
# List stored cues

### load

`cue load <name>`
Instantly recall a cue

### fade
`cue fade <name> <ms>`
Fade current state to cue

### delete
`cue delete <name>`
Remove cue

# Files

Cues are stored in a file in the same directory as the script :

cues.json


 
