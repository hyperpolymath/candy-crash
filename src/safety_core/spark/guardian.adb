-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2026 Hyperpolymath
--
-- Candy Crash Safety Guardian
-- Telemetry Validation and Hardware Protection
--
-- This module implements the cryptographic and hardware-range
-- validation for all incoming telemetry packets.

with Interfaces; use Interfaces;
with System; use System;
with SHA256; use SHA256;

package body Guardian is

   -- Configuration constants
   Max_Steering_Angle : constant := 900.0;  -- Degrees
   Max_G_Force : constant := 5.0;         -- G's
   Max_Tire_Temp : constant := 200.0;      -- Celsius
   Max_Brake_Pressure : constant := 100.0; -- Percentage

   -- HMAC-SHA256 validation for packet integrity
   function Validate_Packet(
      Packet : Telemetry_Packet;
      Key : HMAC_Key)
      return Boolean
   is
      Computed_HMAC : HMAC_Digest;
      Expected_HMAC : HMAC_Digest := Packet.HMAC;
   begin
      -- Compute HMAC of packet data
      Computed_HMAC := Compute_HMAC(
         Key,
         Packet.Data,
         Packet.Data'Length
      );

      -- Compare with expected HMAC
      return Computed_HMAC = Expected_HMAC;
   end Validate_Packet;

   -- Hardware range validation for individual values
   function Valid_Range(
      Value : Float;
      Min : Float;
      Max : Float)
      return Boolean
   is
   begin
      return Value >= Min and Value <= Max;
   end Valid_Range;

   -- Comprehensive telemetry validation
   function Validate_Telemetry(
      Packet : Telemetry_Packet)
      return Validation_Result
   is
      -- Secret key would be injected at build time
      Secret_Key : constant HMAC_Key := Get_Secret_Key;
   begin
      -- Step 1: Cryptographic validation
      if not Validate_Packet(Packet, Secret_Key) then
         return Invalid_Signature;
      end if;

      -- Step 2: Hardware range checks
      -- Steering angle validation
      if not Valid_Range(
         Packet.Steering_Angle,
         -Max_Steering_Angle,
         Max_Steering_Angle) then
         return Invalid_Range;
      end if;

      -- G-force validation
      if not Valid_Range(
         abs(Packet.Longitudinal_G),
         0.0,
         Max_G_Force) then
         return Invalid_Range;
      end if;

      if not Valid_Range(
         abs(Packet.Lateral_G),
         0.0,
         Max_G_Force) then
         return Invalid_Range;
      end if;

      -- Tire temperature validation
      for I in Packet.Tire_Temps'Range loop
         if not Valid_Range(
            Packet.Tire_Temps(I),
            0.0,
            Max_Tire_Temp) then
            return Invalid_Range;
         end if;
      end loop;

      -- Brake pressure validation
      if not Valid_Range(
         Packet.Brake_Pressure,
         0.0,
         Max_Brake_Pressure) then
         return Invalid_Range;
      end if;

      -- Speed validation (0-300 km/h)
      if not Valid_Range(
         Packet.Speed_KPH,
         0.0,
         300.0) then
         return Invalid_Range;
      end if;

      -- If all checks pass
      return Valid;
   end Validate_Telemetry;

   -- Emergency stop procedure
   procedure Emergency_Stop is
   begin
      -- Cut power to all actuators
      HAL.Cut_Actuator_Power;
      
      -- Log critical event
      HAL.Log_Critical_Event("EMERGENCY_STOP");
      
      -- Broadcast audible alert
      HAL.Broadcast_Audible_Alert;
      
      -- Reset system to safe state
      HAL.Reset_To_Safe_State;
   end Emergency_Stop;

end Guardian;