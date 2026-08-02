import { describe, expect, test } from 'vitest';
import { createConnectedPeriphsStore } from './connectedPeriphs';

describe('setPeriphs', () => {
  test("replaces the connected peripheral map", () => {
    const store = createConnectedPeriphsStore();

    const newPeriphs = {
      "periph1": 1,
      "periph2": 2,
    };
    store.getState().setPeriphs(newPeriphs);

    const periphs = store.getState().periphs;
    expect(periphs).toEqual(newPeriphs);
  });
});