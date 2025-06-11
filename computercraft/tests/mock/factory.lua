return {
  groups = {
    ["minecraft:dropper_1:g1"] = {
      id = "minecraft:dropper_1:g1",
      nickname = "Inventory",
      slots = { {
        periphId = "minecraft:dropper_1",
        slot = 1
      }, {
        periphId = "minecraft:dropper_1",
        slot = 2
      }, {
        periphId = "minecraft:dropper_1",
        slot = 3
      }, {
        periphId = "minecraft:dropper_1",
        slot = 4
      }, {
        periphId = "minecraft:dropper_1",
        slot = 5
      }, {
        periphId = "minecraft:dropper_1",
        slot = 6
      }, {
        periphId = "minecraft:dropper_1",
        slot = 7
      }, {
        periphId = "minecraft:dropper_1",
        slot = 8
      }, {
        periphId = "minecraft:dropper_1",
        slot = 9
      } },
    },
    ["minecraft:dispenser_1:g1"] = {
      id = "minecraft:dispenser_1:g1",
      nickname = "Inventory",
      slots = { {
        periphId = "minecraft:dispenser_1",
        slot = 1
      }, {
        periphId = "minecraft:dispenser_1",
        slot = 2
      }, {
        periphId = "minecraft:dispenser_1",
        slot = 3
      }, {
        periphId = "minecraft:dispenser_1",
        slot = 4
      }, {
        periphId = "minecraft:dispenser_1",
        slot = 5
      }, {
        periphId = "minecraft:dispenser_1",
        slot = 6
      }, {
        periphId = "minecraft:dispenser_1",
        slot = 7
      }, {
        periphId = "minecraft:dispenser_1",
        slot = 8
      }, {
        periphId = "minecraft:dispenser_1",
        slot = 9
      } },
    },
    ["minecraft:dropper_2:g1"] = { id="minecraft:dropper_2:g1" },
    ["minecraft:dropper_3:g1"] = { id="minecraft:dropper_3:g1" },
  },
  machines = {
    ["minecraft:dropper_1"] = {
      id = "minecraft:dropper_1",
      groups = { "minecraft:dropper_1:g1" }
    },
    ["minecraft:dispenser_1"] = {
      id = "minecraft:dispenser_1",
      groups = { "minecraft:dispenser_1:g1" }
    },
  },
  pipes = {
    ["pipe1"] = {
      id = "pipe1",
      from = "minecraft:dropper_1:g1",
      to = "minecraft:dispenser_1:g1",
    },
    ["pipe2"] = {
      id = "pipe2",
      from = "minecraft:dropper_1:g1",
      to = "minecraft:dispenser_1:g1",
    },
    ["pipe3"] = {
      id = "pipe3",
      from = "minecraft:dropper_1:g1",
      to = "minecraft:dispenser_1:g1",
    },
    ["pipe4"] = {
      id = "pipe4",
      from = "minecraft:dispenser_2:g1",
      to = "minecraft:dispenser_3:g1",
    },
    ["pipe5"] = {
      id = "pipe5",
      from = "minecraft:dispenser_2:g1",
      to = "minecraft:dispenser_4:g1",
    },
  }
}