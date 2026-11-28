# Questions for the owner

Decisions the config cannot make on its own. Each one lists the default that is in place now.

## Screenshot editor

satty (GTK4) was removed with its `SUPER+Print` key; the other screenshot keys are unchanged.
Every screenshot annotator in nixpkgs (satty, swappy, waytator, pinsel, ksnip) is GTK or Qt, and
annotating needs a drawing surface, so there is no terminal one. *Default: no editor.*
