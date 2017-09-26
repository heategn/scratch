These are a collection of experimental utilities I created for learning and personal use.

# bash/ufeasy

![ufeasy](https://github.com/heategn/scratch/blob/master/bash/ufeasy/ufeasy.png)

A utility for the **ufw** command that saves time managing rules. It reads a flat file containing the rules, then provides an interface to activate and deactivate those rules via  the **ufw** command. It also allows the user to add and remove rules directly from the utility.

There is a "synchronize" option that will populate a new flat file based on the currently loaded **ufw** rules. Note that this will overwrite the previous file if it exists.

Future improvements could include a method to generate rules using a guided process instead of requiring the user to write the rule by hand.

Bash 4.3.48 (Not guaranteed to be portable nor bug-free)
