import { GroupId, Slot } from "@server/types/core-types";
import { GroupDelReq, GroupEditReq, MachineDelReq, MachineEditReq } from "@server/types/messages";
import { Dispatch, SetStateAction } from "react";
import { SendMessage } from "react-use-websocket";
import { Node } from "reactflow";
import { v4 as uuidv4 } from "uuid";

/**
 * Combine 1 or more source machines into a target Machine
 * - Groups from the source machines will be moved into the target machine
 * - The source machines will then de deleted
 * @param sourceMachineNodes Machines that will be combined into the target
 * @param targetMachineNode Machine that will be combined into
 * @param setNodes React Flow node setter
 * @param sendMessage WebSocket sendMessage handle
 */
function combineMachines(
  sourceMachineNodes: Node[],
  targetMachineNode: Node,
  setNodes: Dispatch<SetStateAction<Node[]>>,
  sendMessage: SendMessage
) {
  // get the machine's groups and tell cc to add them to the drop target's group list
  const combinedGroupList: GroupId[] = sourceMachineNodes.reduce(
    (combinedList, sourceMachineNode) => [...combinedList, ...sourceMachineNode.data.machine.groups],
    [...targetMachineNode.data.machine.groups]
  );
  
  sendMessage(JSON.stringify({
    type: "MachineEdit",
    reqId: uuidv4(),
    machineId: targetMachineNode.id,
    edits: {
      groups: combinedGroupList,
    }
  } as MachineEditReq));

  // tell cc to delete the dragged machine
  for (let machineNode of sourceMachineNodes) {
    sendMessage(JSON.stringify({
      type: "MachineDel",
      reqId: uuidv4(),
      machineId: machineNode.id,
    } as MachineDelReq));
  }

  // set the parent of the dragged machine's group nodes to the target machine
  // and delete the dragged machine's node
  const sourceMachineNodeIds = sourceMachineNodes.map(node => node.id);
  setNodes(nodes => nodes
    .filter(node => !sourceMachineNodeIds.includes(node.id))
    .map(node => {
      if ( sourceMachineNodeIds.includes(node.parentId as string) ) {
        return {...node, parentId: targetMachineNode.id}
      }
      return node
    })
  );
}

/**
 * Combine 1 or more source groups with a target group
 * - Slots from the source groups will be moved into the target group
 * - The source groups will then be deleted
 * @param sourceGroupNodes Groups that will be combined into the target
 * @param targetGroupNode Group to combine into
 * @param setNodes React Flow node setter
 * @param sendMessage WebSocket sendMessage handle
 */
function combineGroups(
  sourceGroupNodes: Node[],
  targetGroupNode: Node,
  setNodes: Dispatch<SetStateAction<Node[]>>,
  sendMessage: SendMessage
) {
  // get the group's slots and tell cc to add them to the target group's slot list
  const combinedSlotList: Slot[] = sourceGroupNodes.reduce(
    (combinedList, sourceGroupNodes) => [...combinedList, ...sourceGroupNodes.data.group.slots],
    [...targetGroupNode.data.group.slots]
  );

  sendMessage(JSON.stringify({
    type: "GroupEdit",
    groupId: targetGroupNode.id,
    edits: {
      slots: combinedSlotList,
    }
  } as GroupEditReq));

  // tell cc to delete the source group
  // TODO: make the CC side remove the group from the source machine's list of groups
  for (let groupNode of sourceGroupNodes) {
    sendMessage(JSON.stringify({
      type: "GroupDel",
      groupId: groupNode.id,
    } as GroupDelReq));
  }

  // set the parent of the group's slot nodes to the target group
  // and delete the source group's node
  const sourceGroupNodeIds = sourceGroupNodes.map(node => node.id);
  setNodes(nodes => nodes
    .filter(node => !sourceGroupNodeIds.includes(node.id))
    .map(node => {
      if ( sourceGroupNodeIds.includes(node.parentId as string) ) {
        return { ...node, parentId: targetGroupNode.id }
      }
      return node
    })
  )
}

export const CombineHandlers = {
  combineMachines: combineMachines,
  combineGroups: combineGroups,
};