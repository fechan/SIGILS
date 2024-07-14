# Shack Industries Graphical Item Logistics Software
The **Shack Industries Graphical Item Logistics Software** (SIGILS) is a ComputerCraft program for transferring items between Minecraft inventories and machines that are connected by a wired modem to a ComputerCraft computer.

Using the SIGILS Editor on a web browser, virtual item pipes can be created between chests, furnaces, and/or modded inventories to transfer items between their slots. Filters can be added for even more flexibility, allowing you to create automated factories entirely using SIGILS.

![SIGILS in action](https://github.com/fechan/SIGILS/assets/56131910/dbac2bf4-93ad-466a-bd91-dfe622ec4fd6)

## Requirements
* Minecraft 1.16 or greater
* CC: Tweaked 1.94.0 or greater
* Any non-portable ComputerCraft computer (including turtles)
* Wired modems (from CC: Tweaked. The full-block versions are more convenient to use.)
* (Optional) Networking cable (from CC: Tweaked)

## Installation and usage

### Connecting machines to your ComputerCraft computer
1. Put down your computer somewhere convenient
2. Put a wired modem next to the computer.
    * If the modem has no red on it, right click it to add it to the computer's network
3. Place wired modems next to any machines you want to pipe items to/from
    * Again, if the modem block has no red on it, right click it
4. Connect up the modems using either networking cable or more modems
    * As long as the computer and the machines are connected by modems and cables, SIGILS will detect it
5. If you need to add more machines later, connect them up to the existing network with more modems. You can do this regardless of whether SIGILS is running or not

### Installing SIGILS on your ComputerCraft computer
1. In a ComputerCraft computer (can be basic or advanced, turtle or regular) type `wget run https://sigils.fredchan.org/install` and press Enter
2. If prompted to make SIGILS run on startup, press Y
3. After installation finishes, type `sigils` and press Enter

### Making and editing pipes
1. In SIGILS, press E to enter editing mode and take note of the 4-letter session code
2. In your web browser, go to [sigils.fredchan.org](https://sigils.fredchan.org) and enter the session code
3. Press "Start editing"
4. Click and drag from any red handle into any blue handle to pipe items from one inventory to another. Congratulations, you've made your first pipe!
5. When you're all done, go back into your ComputerCraft computer and press E again to exit editing mode