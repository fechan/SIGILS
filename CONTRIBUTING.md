Thanks for your interest in SIGILS! Since this was just a personal project, I didn't really expect anyone to be interested in developing for SIGILS, so it might be a little rough around the edges.

During development, I tried to comment as much of the function signatures and classes as I could remember to. If you have any questions, feel free to reach out to me on GitHub issues.

## Before you start
**Always develop on 1.16.5 with CC:Tweaked 1.101.3.** The Generic Inventory and Fluid peripheral APIs were introduced during Minecraft 1.16.5, and 1.101.3 is the last version of CC: Tweaked for that version of Minecraft.

As long as you're using those versions, your changes will likely work on higher versions and still be compatible with as many old versions as possible. **If you use newer versions of Minecraft/CC: Tweaked, you risk breaking backward-compatibility.**

## General overview
* `/computercraft` contains the Lua code for SIGILS that runs on ComputerCraft computers. It normally doesn't need to talk to the server, unless the user puts it in Editing mode by pressing `E`.
  * When in editing mode, it asks the server to start an editing session with a certain code. If the code is available, it is shown to the user.
* `/server` contains the editor session server that relays messages between ComputerCraft and the SIGILS editor, written in TypeScript. It also has the TypeScript definitions that are used everywhere in `/server/src/types`.
  * `core-types.ts` is the most important because these are the data types for Factory, Machine, Slot, Group, and Pipe. These types can be serialized into JSON and given to ComputerCraft to unserialize into a table.
* `/client` contains the editor, written in React, React Flow (the library for building the flowchart editor), Zustand (for storing the Factory state as to comes in from the server), and TypeScript.
  * Initially, the client asks the server for the full state of the Factory from ComputerCraft. ComputerCraft will send JSON and the server will relay it to the client.
  * Whenever the user makes an edit, the client sends an edit message in JSON and the server will relay it to ComputerCraft.
  * If ComputerCraft changes the state of the Factory, it will send JSON consisting of only the changes.

## Running in the development environment
1. From `/server`, run `npm run dev` to start the server.
2. From `/client`, run `npm run dev` to start the client/editor.
3. Take note of the address that appears after starting the client and open that in your browser.
4. You will want to somehow keep the contents `/computercraft` synced to a ComputerCraft computer, so that changes you make to it can be tested in-game.
  * The way I do this is to create a symlink to the `/computercraft` inside the ComputerCraft filesystem at `.minecraft/saves/<world-name>/computercraft/computer/<computer-id>`.
5. Make sure ComputerCraft can access the SIGILS server. If you are running it on localhost, you will need to [allow access to local IPs](https://tweaked.cc/guide/local_ips.html).
6. Run SIGILS and close it. This will create `sigils-config.json` in the same directory.
7. Modify `server` in `sigils-config.json` to the address of your dev server (probably `ws://localhost:3000`).
8. Restart SIGILS and check that it actually connects to your dev server. If it does, congratulations! You can start developing.