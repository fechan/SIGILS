import { Factory, Group, GroupId, Machine, MachineId, PeriphId, Pipe, PipeId } from "./core-types"
import { ErrorType } from "./errors";
import { SessionId } from "./session";
import { Delta } from "jsondiffpatch";

export const FACTORY_UPDATE_REQUEST_TYPES = [
  "PipeAdd", "PipeEdit", "PipeDel",
  "MachineAdd", "MachineEdit", "MachineDel",
  "GroupAdd", "GroupEdit", "GroupDel",
  "PeriphAdd", "PeriphDel",
] as const;

export type FactoryUpdateRequest = typeof FACTORY_UPDATE_REQUEST_TYPES[number];

export type MessageType = (
  "BatchRequest" |
  "ConfirmationResponse" |
  "IdleTimeout" |
  "SessionCreate" | "SessionJoin" | "SessionRejoin" |
  "FactoryGet" | "FactoryGetResponse" |
  FactoryUpdateRequest |
  "CcUpdatedFactory"
);

export interface Message {
  type: MessageType,
};

export interface Request extends Message {
  reqId: string,
};

/**
 * A series of requests for ComputerCraft to execute in order.
 * 
 * This should be used if multiple related requests need to be issued, such as
 * for Machine-to-Machine combination.
 * 
 * - Only emitted from the editor
 */
export interface BatchRequest extends Request {
  type: "BatchRequest",
  requests: Request[],
}

/**
 * A response confirming the success of a request.
 * 
 * - CC should always respond to requests
 * - The server should always relay responses from CC to the editor
 * - The server should only respond to `SessionCreate` requests from CC
 *   and `SessionJoin` requests from the editor
 * - The editor should never respond to requests from CC
 */
export interface ConfirmationResponse extends Message {
  type: "ConfirmationResponse"
  respondingTo: MessageType,
  reqId?: string,
  ok: boolean,
};

export interface SuccessResponse extends ConfirmationResponse {
  ok: true,
}

export interface FailResponse extends ConfirmationResponse {
  ok: false,
  error: ErrorType,
  message: string,
}

export interface IdleTimeout extends Message {
  type: "IdleTimeout"
  message: string,
}

/**
 * Request for the creation of an editor session accessible via a session ID
 * 
 * - Emitted from CC
 * - Not emitted from the editor
 */
export interface SessionCreateReq extends Request {
  type: "SessionCreate",
  sessionId: SessionId,
};

export interface SessionCreateRes extends ConfirmationResponse {
  ccReconnectToken: string,
}

/**
 * Request for joining an editor session via a session ID
 * 
 * - Not emitted from CC
 * - Emitted from the editor when the user inserts a session ID
 */
export interface SessionJoinReq extends Request {
  type: "SessionJoin",
  sessionId: SessionId,
}

export interface SessionRejoinReq extends Request {
  type: "SessionRejoin",
  ccReconnectToken: string,
  sessionId: SessionId,
}

/**
 * Request for the full factory definition
 * 
 * - Not emitted from CC
 * - Emitted from the editor after joining a session
 */
export interface FactoryGetReq extends Request {
  type: "FactoryGet",
}

/**
 * Response to FactoryGet, containing the factory definition
 * 
 * - Emitted from CC after receiving FactoryGet
 * - Not emitted from the editor
 */
export interface FactoryGetRes extends SuccessResponse {
  respondingTo: "FactoryGet"
  reqId: string,
  factory: Factory,
}

/**
 * Response to any request that updates the factory
 * 
 * - Emitted from CC after modifying the factory due to an editor request
 * - Not emitted from the editor
 */
export interface FactoryUpdateRes extends SuccessResponse {
  respondingTo: FactoryUpdateRequest,
  reqId: string,
  diff: Delta[],
}

/**
 * Request to add a Pipe to the factory.
 * 
 * - Not emitted from CC
 * - Emitted from the editor if a new pipe is added by the user
 */
export interface PipeAddReq extends Request {
  type: "PipeAdd",
  pipe: Pipe,
}

/**
 * Request to edit a Pipe in the factory.
 * 
 * - Not emitted from CC
 * - Emitted from the editor if a pipe is edited by the user
 */
export interface PipeEditReq extends Request {
  type: "PipeEdit",
  pipeId: PipeId,
  edits: Partial<Pipe>,
}

/**
 * Request to delete a Pipe in the factory.
 * 
 * - Not emitted from CC
 * - Emitted from the editor if a pipe is deleted by the user
 */
export interface PipeDelReq extends Request {
  type: "PipeDel",
  pipeId: PipeId,
}

/**
 * Request to add a Machine to the factory.
 * 
 * - Emitted from CC if it detects a new peripheral is connected to the
 * network
 * - Emitted from the editor if a peripheral is split off from a Machine pool
 */
export interface MachineAddReq extends Request {
  type: "MachineAdd",
  machine: Machine,
}

/**
 * Request to edit a Machine in the factory.
 * 
 * - Emitted from the editor when Machines are combined or Machine attributes are edited by the user
 */
export interface MachineEditReq extends Request {
  type: "MachineEdit",
  machineId: MachineId,
  edits: Partial<Machine>,
}

/**
 * Request to delete a Machine in the factory
 * 
 * - Emitted from the editor when Machines are combined
 */
export interface MachineDelReq extends Request {
  type: "MachineDel",
  machineId: MachineId,
}

/**
 * Request to delete a Group in the factory
 * 
 * - Emitted from the editor when Groups are combined, or when Machines with similarly named Groups are combined
 */
export interface GroupDelReq extends Request {
  type: "GroupDel",
  groupId: GroupId,
}

/**
 * Request to edit a Group in the factory.
 * 
 * - Emitted from the editor when Groups are combined, Machines with similar Groups are combined, or Group attributes are edited by the user
 */
export interface GroupEditReq extends Request {
  type: "GroupEdit",
  groupId: GroupId,
  edits: Partial<Group>,
}

/**
 * Request to add a Group to the factory under a Machine
 */
export interface GroupAddReq extends Request {
  type: "GroupAdd",
  group: Group,
  machineId: MachineId,
}

/**
 * Request to add a peripheral to the factory as a Machine
 * You can optionally specify machine options to initialize the Machine with
 */
export interface PeriphAddReq extends Request {
  type: "PeriphAdd",
  periphId: PeriphId,
  options?: Partial<Machine>,
}

/**
 * Request to delete a peripheral from the factory.
 * 
 * - Emitted from the editor when the user wants to delete a missing peripheral
 */
export interface PeriphDelReq extends Request {
  type: "PeriphDel",
  periphId: PeriphId,
}

/**
 * Unilateral declaration by ComputerCraft that it has updated the factory.
 * 
 * - Emitted from CC when peripherals are attached or detached from the network.
 */
export interface CcUpdatedFactory extends Message {
  type: "CcUpdatedFactory",
  diff: Delta[],
}