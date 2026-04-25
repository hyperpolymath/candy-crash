-- SPDX-License-Identifier: PMPL-1.0-or-later
-- SPDX-FileCopyrightText: 2026 Hyperpolymath
--
-- Candy Crash Hardware Watchdog
-- Real-time Monitoring and Emergency Response
--
-- This module implements the hardware watchdog timer
-- that ensures system responsiveness and triggers
-- emergency procedures when needed.

with Ada.Real_Time; use Ada.Real_Time;
with HAL; use HAL;
with System; use System;

package body Watchdog is

   -- Watchdog configuration
   Heartbeat_Timeout : constant Time_Span := Milliseconds(10);
   Last_Heartbeat : Time := Clock;
   Watchdog_Enabled : Boolean := True;

   -- Feed the watchdog timer
   procedure Feed_Watchdog is
   begin
      if Watchdog_Enabled then
         Last_Heartbeat := Clock;
         HAL.Set_Watchdog_Timer(Heartbeat_Timeout);
      end if;
   end Feed_Watchdog;

   -- Check watchdog status
   function Check_Watchdog return Boolean is
      Current_Time : constant Time := Clock;
   begin
      if not Watchdog_Enabled then
         return True;
      end if;

      -- Check if timeout has occurred
      if Current_Time - Last_Heartbeat > Heartbeat_Timeout then
         Emergency_Stop("WATCHDOG_TIMEOUT");
         return False;
      end if;

      return True;
   end Check_Watchdog;

   -- Enable watchdog monitoring
   procedure Enable_Watchdog is
   begin
      Watchdog_Enabled := True;
      Last_Heartbeat := Clock;
      HAL.Initialize_Watchdog;
   end Enable_Watchdog;

   -- Disable watchdog (for maintenance)
   procedure Disable_Watchdog is
   begin
      Watchdog_Enabled := False;
      HAL.Disable_Watchdog;
   end Disable_Watchdog;

   -- Emergency stop procedure
   procedure Emergency_Stop(Reason : String) is
   begin
      -- Log the reason for emergency stop
      HAL.Log_Critical_Event("WATCHDOG_STOP: " & Reason);

      -- Cut power to all actuators immediately
      HAL.Cut_Actuator_Power;

      -- Broadcast audible alert
      HAL.Broadcast_Audible_Alert;

      -- Reset system to safe state
      HAL.Reset_To_Safe_State;

      -- Disable watchdog to prevent recursive triggers
      Disable_Watchdog;
   end Emergency_Stop;

   -- Periodic watchdog check task
   task body Watchdog_Task is
   begin
      loop
         -- Check watchdog every 1ms
         delay until Clock + Milliseconds(1);

         -- Verify watchdog status
         if not Check_Watchdog then
            -- Watchdog has triggered emergency stop
            -- Task will terminate after emergency stop
            return;
         end if;
      end loop;
   end Watchdog_Task;

begin
   -- Start watchdog task when package is elaborated
   null;
end Watchdog;