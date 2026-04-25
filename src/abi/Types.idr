module CandyCrash.ABI.Types

import Data.Bits
import Data.Buffer

-- SPDX-License-Identifier: PMPL-1.0-or-later

public export
data Handle : Type where
  MkHandle : (ptr : Bits64) -> {auto 0 nonNull : So (ptr /= 0)} -> Handle

-- Prove capabilities over the training session
public export
data TrainingCapability = StartSession | EndSession | RequestIntervention | RespondToIntervention

-- Capability Registry (A2ML-backed via Zig)
public export
interface TrainingRegistry where
  startSession : Handle -> IO (Either String Handle)
  endSession   : Handle -> IO (Either String ())

public export
data ResultCode = Success | ErrorAuth | ErrorInvalid | ErrorTimeout

public export
toResultCode : Bits32 -> ResultCode
toResultCode 0 = Success
toResultCode 1 = ErrorAuth
toResultCode 2 = ErrorInvalid
toResultCode _ = ErrorTimeout
