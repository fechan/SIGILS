import { stringToColor } from "../StringToColor";
import { DragEvent } from "react";
import { useFactoryStore } from "../stores/factory";
import { Peripheral } from "@server/types/core-types";
import { useStore } from "zustand";
import { connectedPeriphsStore } from "../stores/connectedPeriphs";

export interface AvailablePeripheralBadgeProps {
  periphId: string,
  periph: Peripheral,
};

export interface AvailablePeripheralBadgeDragData {
  periphId: string,
  periph: Peripheral,
}

export function AvailablePeripheralBadge({ periphId }: AvailablePeripheralBadgeProps) {
  const factory = useFactoryStore();
  const { periphs, getMissing } = useStore(connectedPeriphsStore);
  const missingPeriphs = getMissing(factory.getPeripheralNames());

  function onDragStart(event: DragEvent<HTMLSpanElement>) {
    const dragData: AvailablePeripheralBadgeDragData = { periphId: periphId, periph: periphs[periphId] };
    event.dataTransfer.setData("application/ccpipes-peripheraladd", JSON.stringify(dragData));
    event.dataTransfer.effectAllowed = "move";
  }

  return (
    <span
      draggable
      className={
        "nodrag rounded py-0.5 px-2 text-xs me-1 bg-blue-500 text-white " +
        "relative hover:-top-0.5 hover:shadow " +
        (missingPeriphs.has(periphId) ? "opacity-30" : "")
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