# HoH-Class-Changer
A fully balanced Class Changer for Heroes of Hammerwatch with support for Modded Classes.

A NPC will appear in the Armory with a gear above their head.
They will allow you to unlock and train your character to change classes.

For Modders:
To add your modded class to the menu you need to add a support.sval file to your mod files.
the contents will need to include:
```
<loader>ClassChanger::AddClassFile</loader>
<array>
  <dict>
    <string name="class-id">class_id</string>
    <string name="name">Class Name</string>
    <string name="desc">Class Description</string>
    <int name="ore-price">Price</int>
    <array name="flags">
      <string>building_name,building_level</string> 
      <string>dlc_abreviation</string>
      <string>town_flag</string>
    </array>
    <string name="flag-desc">Flag Requirement</string>
  </dict>
</array>
```
"building_name" has support for:
  - apothecary, 
  - blacksmith,
  - chapel,
  - fountain,
  - generalstore,
  - guildhall,
  - magicshop,
  - oretrader,
  - tavern,
  - townhall,
  - treasury,
  
"dlc_abreviation" has support for:
 - pop
 - wh
 - mt
 
"town_flag" has support for:
 - ANY TOWN FLAG (There are too many to list)
  
### EXAMPLE:
Dictionary Listing for Theif:
```
<dict>
  <string name="class-id">thief</string>
  <string name="name">Thief</string>
  <string name="desc">An elusive melee fighter with a lot of mobility.</string>
  <int name="ore-price">20</int>
  <array name="flags">
    <string>tavern,1</string>
  </array>
  <string name="flag-desc">Tavern Unlocked</string>
</dict>
```
