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
  /**
   * @returns A factory where periphs{1,2,3,4} are in factory
   *          and periphs{1,2,5} are connected. 3 and 4 are considered missing.
   */
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
      'periph5': 5,
    };
    store.getState().setPeriphs(connectedPeriphs);

    return {store, factoryPeriphs};
  }

  test("returns missing periphs", () => {
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

describe('getAvailable', () => {
  /**
   * @returns A factory where periphs{1,2,5} are in factory
   *          and periphs{1,2,3,4} are connected. 3 and 4 are considered available.
   */
  function getStateForTest_getAvailable() {
    const store = createConnectedPeriphsStore();

    const factoryPeriphs = new Set([
      'periph1',
      'periph2',
      'periph5',
    ]);
    const connectedPeriphs = {
      'periph1': 1,
      'periph2': 2,
      'periph3': 3,
      'periph4': 4,
    };
    store.getState().setPeriphs(connectedPeriphs);

    return {store, factoryPeriphs};
  }

  test("returns available periphs", () => {
    const { store, factoryPeriphs } = getStateForTest_getAvailable();

    const available = store.getState().getAvailable(factoryPeriphs);

    expect(available).toContain('periph3');
    expect(available).toContain('periph4');
  });

  test("does not return periphs already in factory", () => {
    const { store, factoryPeriphs } = getStateForTest_getAvailable();

    const available = store.getState().getAvailable(factoryPeriphs);

    expect(available).not.toContain('periph1');
    expect(available).not.toContain('periph2');
  });
});