import { describe, expect, test } from 'vitest'
import { Factory } from '@server/types/core-types.js';
import { addGroups, addMachines, splitSlotFromGroup } from './factory.js';

function getEmptyFactory() {
  return {
    machines: {},
    pipes: {},
    groups: {},
    missing: {},
    available: {},
  } as Factory;
}

test("Adding a new group with a machine specified adds the group to machine's group list", () => {
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

describe('splitSlotFromGroup', () => {
  function getFactory_OneMachine_OneGroup_TwoSlots() {
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
    const factory = getFactory_OneMachine_OneGroup_TwoSlots();

    splitSlotFromGroup(factory, {periphId: 'periph0', slot: 1}, 'group0', 'machine0', 0, 0);

    expect(factory.machines['machine0'].groups.length).toBe(2);
    for (const groupId of factory.machines['machine0'].groups) {
      if (groupId !== 'group0') {
        expect(factory.groups[groupId].slots).toContainEqual({periphId: 'periph0', slot: 1});
      }
    }
  });

  test("removes the slot from the source group", () => {
    const factory = getFactory_OneMachine_OneGroup_TwoSlots();
    
    splitSlotFromGroup(factory, {periphId: 'periph0', slot: 1}, 'group0', 'machine0', 0, 0);

    expect(factory.groups['group0'])
      .not.toContainEqual({periphId: 'periph0', slot: 1});
  });

  test("leaves the other slots in the source group", () => {
    const factory = getFactory_OneMachine_OneGroup_TwoSlots();
    
    splitSlotFromGroup(factory, {periphId: 'periph0', slot: 1}, 'group0', 'machine0', 0, 0);

    expect(factory.groups['group0'].slots).toContainEqual({periphId: 'periph0', slot: 0});
  });
});

describe('splitPeripheralFromMachine', () => {
  test("creates a new machine", { todo: true }, () => {});
  test("new machine's groups named like the source machine's groups", { todo: true }, () => {});
  test("new machine has no empty groups", { todo: true }, () => {});
  test("removes the peripheral's slots from the source machine", { todo: true }, () => {});
  test("removes newly emptied groups from the source machine", { todo: true }, () => {});
});