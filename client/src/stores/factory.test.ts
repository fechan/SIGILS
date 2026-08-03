import { describe, expect, test } from 'vitest';
import { Factory } from '@server/types/core-types.js';
import { addGroups, addMachines, addPeripheralAsMachine, combineGroups, splitSlotFromGroup } from './factory.js';

function getEmptyFactory() {
  return {
    machines: {},
    pipes: {},
    groups: {},
  } as Factory;
}

describe('addGroups', () => {
  test("adds the group to the machine's group list if a machine is specified", () => {
    const factory = getEmptyFactory();
    addMachines(factory, [{
      id: 'machine0',
      groups: [],
    }]);

    addGroups(factory, [{
      id: 'group0',
      nickname: 'group0',
      slots: [{periphId: 'periph0', slot: 0}],
    }], 'machine0');

    expect(factory.machines['machine0'].groups).contain('group0');
  });
});

describe('combineGroups', () => {
  /**
   * @returns A factory with one machine `machine0`, which contains 3 groups
   *          `group-target`, `group-source0`, and `group-source1` containing
   *          slots 0, 1, and 2 from `periph0` respectively.
   */
  function getFactoryForTest_combineGroups() {
    const factory = getEmptyFactory();

    addMachines(factory, [{ id: 'machine0', groups: [] }]);

    addGroups(factory, [
      {
        id: 'group-target',
        slots: [{ periphId: 'periph0', slot: 0 }]
      },
      {
        id: 'group-source0',
        slots: [
          { periphId: 'periph0', slot: 1 },
        ]
      },
      {
        id: 'group-source1',
        slots: [
          { periphId: 'periph0', slot: 2 },
        ]
      },
    ], 'machine0');

    return factory;
  }

  test("slots from the source become part of the target", () => {
    const factory = getFactoryForTest_combineGroups();

    combineGroups(factory, ['group-source0', 'group-source1'], 'group-target');

    for (const slotNbr of [0, 1, 2]) {
      expect(factory.groups['group-target'].slots)
        .toContainEqual({ periphId: 'periph0', slot: slotNbr });
    }
  });

  test("deletes the source groups", () => {
    const factory = getFactoryForTest_combineGroups();

    combineGroups(factory, ['group-source0', 'group-source1'], 'group-target');

    for (const sourceGroupId of ['group-source0', 'group-source1']) {
      expect(Object.keys(factory.groups)).not.toContain(sourceGroupId);
    }
  });
});

describe('combineMachines', () => {
  test("groups with unique names from the source machines are moved into the target", { todo: true }, () => {});
  test("groups that are named the same are combined at the target", { todo: true }, () => {});
  test("deletes the source machines", { todo: true }, () => {});
  test("target machine's groups has all the slots", { todo: true }, () => {});
});

describe('splitSlotFromGroup', () => {
  /**
   * @returns A factory containing 1 machine `machine0`, which has 1 group `group0`.
   *          The group contains slots 0 and 1 from `periph0`.
   */
  function getFactoryForTest_splitSlotFromGroup() {
    const factory = getEmptyFactory();
    addMachines(factory, [{
      id: 'machine0',
      groups: [],
    }]);
    addGroups(factory, [{
      id: 'group0',
      nickname: 'group0',
      slots: [
        {periphId: 'periph0', slot: 0},
        {periphId: 'periph0', slot: 1},
      ],
    }], 'machine0');

    return factory;
  }

  test("creates a new group in the same machine", () => {
    const factory = getFactoryForTest_splitSlotFromGroup();

    splitSlotFromGroup(factory, {periphId: 'periph0', slot: 1}, 'group0', 'machine0', 0, 0);

    expect(factory.machines['machine0'].groups.length).toBe(2);
    for (const groupId of factory.machines['machine0'].groups) {
      if (groupId !== 'group0') {
        expect(factory.groups[groupId].slots).toContainEqual({periphId: 'periph0', slot: 1});
      }
    }
  });

  test("removes the slot from the source group", () => {
    const factory = getFactoryForTest_splitSlotFromGroup();
    
    splitSlotFromGroup(factory, {periphId: 'periph0', slot: 1}, 'group0', 'machine0', 0, 0);

    expect(factory.groups['group0'])
      .not.toContainEqual({periphId: 'periph0', slot: 1});
  });

  test("leaves the other slots in the source group", () => {
    const factory = getFactoryForTest_splitSlotFromGroup();
    
    splitSlotFromGroup(factory, {periphId: 'periph0', slot: 1}, 'group0', 'machine0', 0, 0);

    expect(factory.groups['group0'].slots).toContainEqual({periphId: 'periph0', slot: 0});
  });
});

describe('splitPeripheralFromMachine', () => {

  /**
   * @returns A factory containing 1 machine `machine0`, which has 3 groups
   *          `group-allPeriph0`, `group-mixedPeriphs`, and `group-noPeriph0`.
   *          - `group-allPeriph0` has only 1 slot from `periph0`.
   *          - `group-mixedPeriphs` has 1 slot each from `periph0` and `periph1`.
   *          - `group-noPeriph0` has no slots from `periph0`, only a slot from `periph1`.
   */
  function getFactoryForTest_splitPeripheralFromMachine() {
    const factory = getEmptyFactory();

    addMachines(factory, [{ id: 'machine0', groups: [] }]);

    addGroups(factory, [
      {
        id: 'group-allPeriph0',
        nickname: 'Group of only periph0 slots',
        slots: [{ periphId: 'periph0', slot: 0 }]
      },
      {
        id: 'group-mixedPeriphs',
        nickname: 'Group with mixed periph0 and periph1 slots',
        slots: [
          { periphId: 'periph0', slot: 1 },
          { periphId: 'periph1', slot: 0 },
        ]
      },
      {
        id: 'group-noPeriph0',
        nickname: 'Group with no periph0 slots',
        slots: [{ periphId: 'periph1', slot: 1 }]
      },
    ], 'machine0');

    return factory;
  }

  test("adds a new machine", { todo: true }, () => {});
  test("new machine's groups named like the source machine's groups", { todo: true }, () => {});
  test("new machine has no empty groups", { todo: true }, () => {});
  test("removes the peripheral's slots from the source machine", { todo: true }, () => {});
  test("removes newly emptied groups from the source machine", { todo: true }, () => {});
});

describe('addPeripheralAsMachine', () => {
  test("creates a new machine", () => {
    const factory = getEmptyFactory();
    const peripheral = { size: 3, fluidTank: true };

    addPeripheralAsMachine(factory, 'mod:liquefier', peripheral, {});

    expect(Object.keys(factory.machines).length).toBe(1);
  });

  test("adds all item slots when peripheral has both item slots and fluid tanks", () => {
    const factory = getEmptyFactory();
    const peripheral = { size: 3, fluidTank: true };

    addPeripheralAsMachine(factory, 'mod:liquefier', peripheral);

    const newGroups = Object.values(factory.groups).filter(g => !g.fluid);
    expect(newGroups.length).toBe(peripheral.size);
    for (const group of newGroups) {
      expect(Object.values(factory.machines)[0].groups).toContain(group.id);
    }
  });

  test("adds a fluid tanks when peripheral has both item slots and fluid tanks", () => {
    const factory = getEmptyFactory();
    const peripheral = { size: 3, fluidTank: true };

    addPeripheralAsMachine(factory, 'mod:liquefier', peripheral);

    const newFluidGroups = Object.values(factory.groups).filter(g => g.fluid);
    expect(newFluidGroups.length).toBe(1);
    expect(Object.values(factory.machines)[0].groups).toContain(newFluidGroups[0].id);
  });

  test("adds only item slots when peripheral has only item slots", () => {
    const factory = getEmptyFactory();
    const peripheral = { size: 3 };

    addPeripheralAsMachine(factory, 'mod:depot', peripheral);

    const newGroups = Object.values(factory.groups);
    expect(newGroups.length).toBe(peripheral.size);
    for (const group of newGroups) {
      expect(Object.values(factory.machines)[0].groups).toContain(group.id);
    }
  });

  test("adds only a fluid tank when peripheral has only fluid tanks", () => {
    const factory = getEmptyFactory();
    const peripheral = { fluidTank: true };

    addPeripheralAsMachine(factory, 'mod:tank', peripheral);

    const newGroups = Object.values(factory.groups);
    expect(newGroups.length).toBe(1);
  });

  test("sets provided initial options on the new machine", () => {
    const factory = getEmptyFactory();
    const peripheral = { fluidTank: true };
    const initialOptions = { x: 1, y: 2 };

    addPeripheralAsMachine(factory, 'mod:liquefier', peripheral, initialOptions);

    const newMachine = Object.values(factory.machines)[0];
    expect(newMachine.x).toBe(initialOptions.x);
    expect(newMachine.y).toBe(initialOptions.y);
  });
})