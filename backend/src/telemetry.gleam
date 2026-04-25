// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2026 Hyperpolymath
//
// Encrypted Telemetry Processing
// Hybrid RSA/AES encryption with HMAC validation

import gleam/crypto
import gleam/otp
import gleam/udp
import gleam/result

// Telemetry packet structure
@external(erlang, "telemetry", "telemetry_packet")
type TelemetryPacket {
  TelemetryPacket(
    data: List(Int),
    hmac: List(Int),
    sequence: Int,
    timestamp: Int
  )
}

// Encryption keys
@external(erlang, "telemetry", "rsa_keys")
type RsaKeyPair {
  RsaKeyPair(
    public_key: String,
    private_key: String
  )
}

// Telemetry server state
type TelemetryServer {
  TelemetryServer(
    port: Int,
    rsa_keys: RsaKeyPair,
    aes_key: String,
    sequence: Int
  )
}

// Initialize telemetry server
fn init_telemetry_server(port: Int) -> Result(TelemetryServer, String) {
  // Generate RSA key pair
  case crypto.generate_rsa_key_pair() {
    Ok(rsa_keys) -> {
      // Generate initial AES key
      case crypto.generate_aes_key(256) {
        Ok(aes_key) -> {
          Ok(TelemetryServer(port, rsa_keys, aes_key, 0))
        }
        Error(e) -> Error("AES key generation failed: " <> e)
      }
    }
    Error(e) -> Error("RSA key generation failed: " <> e)
  }
}

// Start UDP server
fn start_udp_server(server: TelemetryServer) -> Result(udp.Socket, String) {
  udp.open(server.port)
  |> result.map(fn(socket) {
    udp.receive_loop(socket, fn(packet, socket) {
      handle_encrypted_packet(packet, server, socket)
    })
  })
}

// Handle encrypted packet
fn handle_encrypted_packet(
  packet: List(Int),
  server: TelemetryServer,
  socket: udp.Socket
) -> udp.Socket {
  case decode_packet(packet) {
    Ok(decoded) -> {
      case verify_hmac(decoded, server.aes_key) {
        Ok(_) -> {
          case validate_telemetry_range(decoded) {
            Ok(validated) -> {
              process_telemetry(validated, server)
            }
            Error(_) -> discard_packet("Range validation failed")
          }
        }
        Error(_) -> discard_packet("HMAC verification failed")
      }
    }
    Error(_) -> discard_packet("Packet decoding failed")
  }
  
  udp.receive_loop(socket, fn(packet, socket) {
    handle_encrypted_packet(packet, server, socket)
  })
}

// Decode binary packet
fn decode_packet(binary: List(Int)) -> Result(TelemetryPacket, String) {
  // Implementation would use binary decoding
  // This is a simplified version
  Ok(TelemetryPacket([], [], 0, 0))
}

// Verify HMAC-SHA256
fn verify_hmac(packet: TelemetryPacket, key: String) -> Result(Bool, String) {
  case crypto.hmac_sha256(packet.data, key) {
    Ok(computed_hmac) -> {
      if computed_hmac == packet.hmac {
        Ok(True)
      } else {
        Ok(False)
      }
    }
    Error(e) -> Error("HMAC computation failed: " <> e)
  }
}

// Validate hardware ranges
fn validate_telemetry_range(packet: TelemetryPacket) -> Result(TelemetryPacket, String) {
  // This would call into SPARK guardian via FFI
  case ffi.guardian_validate_telemetry(packet) {
    Ok(_) -> Ok(packet)
    Error(e) -> Error("Range validation failed: " <> e)
  }
}

// Process valid telemetry
fn process_telemetry(packet: TelemetryPacket, server: TelemetryServer) {
  // Forward to appropriate systems
  case packet {
    TelemetryPacket(data, _, sequence, _) -> {
      // Update sequence number
      let new_server = TelemetryServer(
        server.port,
        server.rsa_keys,
        server.aes_key,
        sequence + 1
      )
      
      // Forward to kinaesthetic system
      forward_to_kinaesthetic(data, new_server)
      
      // Forward to olfactory system
      forward_to_olfactory(data, new_server)
      
      // Forward to ambient system
      forward_to_ambient(data, new_server)
    }
  }
}

// Forward to kinaesthetic system
fn forward_to_kinaesthetic(data: List(Int), server: TelemetryServer) {
  // Implementation would send to kinaesthetic processor
}

// Forward to olfactory system
fn forward_to_olfactory(data: List(Int), server: TelemetryServer) {
  // Implementation would send to olfactory controller
}

// Forward to ambient system
fn forward_to_ambient(data: List(Int), server: TelemetryServer) {
  // Implementation would send to ambient lighting
}

// Discard invalid packet
fn discard_packet(reason: String) {
  // Log discarded packet
  ffi.log_discarded_packet(reason)
}

// Key rotation
fn rotate_aes_key(server: TelemetryServer) -> TelemetryServer {
  case crypto.generate_aes_key(256) {
    Ok(new_key) -> TelemetryServer(
      server.port,
      server.rsa_keys,
      new_key,
      server.sequence
    )
    Error(_) -> server  // Keep old key if generation fails
  }
}