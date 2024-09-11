Auto Raid Farm
===
Automatic management of raid farm parties.  
---
* Due to a recent change in Turtle WoW instance reset methods this addon is the ideal way to manage non-raid instance farm resets as well.

This addon requires party members to be in your leader's friend list. And works best with an addon that auto-accepts group invites.  

The intent is that the group forming character adds the farming characters to its friends list and also to `/autorf add` then sits around with this addon on. It will handle inviting the farmers as they come online and kicking them as they go offline.  

The friends list requirement is due to api limitations. This addon is intended to be used with addons like lazypigs which automatially accept invites from friends.  

```
/autorf
```

Example:  
Leader `A` adds `B` and `C` to his friend's list then types `/autorf add a` and `/autorf add b`  
`B` and `C` are then logged into and will be automatically sent invites to `A`'s raid after a short delay to allow addons to load up.  
When `B` logs out he is kicked from the group and will not be re-invited until `C` is also logged out and kicked.  
A new raid will be formed when one of them logs back in after this point.  

* This addon is made by and for `Weird Vibes` of Turtle WoW.  