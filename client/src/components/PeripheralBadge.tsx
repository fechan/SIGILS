import { MachineId } from "@server/types/core-types";
import { stringToColor } from "../StringToColor";
import { DragEvent } from "react";
import { useFactoryStore } from "../stores/factory";
import { useStore } from "zustand";
import { connectedPeriphsStore } from "../stores/connectedPeriphs";

export interface PeripheralBadgeProps {
  periphId: string,
  machineId: MachineId
};

export interface PeripheralBadgeDragData {
  periphId: string,
  oldMachineId: MachineId,
}

export function PeripheralBadge({ periphId, machineId }: PeripheralBadgeProps) {
  const factory = useFactoryStore();
  const { isPeriphMissing } = useStore(connectedPeriphsStore);
  const isMissing = isPeriphMissing(periphId, factory.getPeripheralNames());

  function onDragStart(event: DragEvent<HTMLSpanElement>) {
    const dragData: PeripheralBadgeDragData = {
      periphId: periphId,
      oldMachineId: machineId,
    };
    event.dataTransfer.setData("application/ccpipes-peripheralmove", JSON.stringify(dragData));
    event.dataTransfer.effectAllowed = "move";
  }

  return (
    <span
      draggable
      className={
        "nodrag rounded py-0.5 px-2 text-xs me-1 bg-blue-500 text-white " +
        "relative hover:-top-0.5 hover:shadow " +
        (isMissing ? "opacity-30" : "")
      }
      style={{
        backgroundColor: stringToColor(periphId)
      }}
      onDragStart={ onDragStart }
    >
      { periphId.split(":")[1] || periphId }
    </span>
  );
}