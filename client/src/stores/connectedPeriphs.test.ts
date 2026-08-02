import { describe, expect, test } from 'vitest';
import { createConnectedPeriphsStore } from './connectedPeriphs';

describe('setPeriphs', () => {
  test("replaces the connected peripheral map", () => {
    const store = createConnectedPeriphsStore();

    const newPeriphs = {
      'periph1': 1,
      'periph2': 2,
    };
    store.getState().setPeriphs(newPeriphs);

    const periphs = store.getState().periphs;
    expect(periphs).toEqual(newPeriphs);
  });
});

describe('getMissing', () => {
  function getStateForTest_getMissing() {
    const store = createConnectedPeriphsStore();

    const factoryPeriphs = new Set([
      'periph1',
      'periph2',
      'periph3',
      'periph4',
    ]);
    const connectedPeriphs = {
      'periph1': 1,
      'periph2': 2,
    };
    store.getState().setPeriphs(connectedPeriphs);

    return {store, factoryPeriphs};
  }

  test("identifies missing periphs", () => {
    const { store, factoryPeriphs } = getStateForTest_getMissing();

    const missing = store.getState().getMissing(factoryPeriphs);

    expect(missing).toContain('periph3');
    expect(missing).toContain('periph4');
  });

  test("does not return connected periphs", () => {
    const { store, factoryPeriphs } = getStateForTest_getMissing();

    const missing = store.getState().getMissing(factoryPeriphs);

    expect(missing).not.toContain('periph1');
    expect(missing).not.toContain('periph2');
  });
});