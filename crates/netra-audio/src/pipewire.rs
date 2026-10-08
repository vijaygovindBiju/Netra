use netra_common::models::audio::{AudioRecordStream, AudioSink, AudioSource, AudioStream};
use netra_common::{NetraError, Result};
use std::collections::HashMap;
use std::process::Command;
use tracing::{error, info};

pub struct PipeWireAudioEngine {
    // Maps group_name to loaded module ID
    active_multi_sinks: HashMap<String, u32>,
    previous_default_sink: Option<String>,
    latency_offsets: HashMap<u32, i32>,
}

impl PipeWireAudioEngine {
    pub fn new() -> Self {
        Self {
            active_multi_sinks: HashMap::new(),
            previous_default_sink: None,
            latency_offsets: HashMap::new(),
        }
    }

    /// Queries all physical and virtual audio sinks available in PipeWire
    pub fn get_sinks(&self) -> Result<Vec<AudioSink>> {
        let default_sink_name = Command::new("pactl")
            .arg("get-default-sink")
            .output()
            .ok()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or_default();

        let output = Command::new("pactl")
            .args(["list", "sinks"])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            return Err(NetraError::DBus("Failed to list sinks via pactl".into()));
        }

        let raw = String::from_utf8_lossy(&output.stdout);
        let mut sinks = Vec::new();

        let mut current_id = 0u32;
        let mut current_name = String::new();
        let mut current_desc = String::new();
        let mut current_vol = 100u8;
        let mut current_mute = false;
        let mut current_port = None;

        for line in raw.lines() {
            let trimmed = line.trim();

            if trimmed.starts_with("Sink #") {
                if current_id != 0 {
                    let is_bt = current_name.contains("bluez") || current_desc.to_lowercase().contains("bluetooth");
                    let is_virt = current_name.contains("combine") || current_name.contains("Netra");
                    let offset = self.latency_offsets.get(&current_id).copied().unwrap_or(0);
                    let is_def = !default_sink_name.is_empty() && current_name == default_sink_name;

                    sinks.push(AudioSink {
                        id: current_id,
                        name: current_name.clone(),
                        description: if current_desc.is_empty() { current_name.clone() } else { current_desc.clone() },
                        volume_percent: current_vol,
                        is_muted: current_mute,
                        is_default: is_def,
                        is_bluetooth: is_bt,
                        is_virtual: is_virt,
                        latency_offset_ms: offset,
                        active_port: current_port.clone(),
                    });
                }

                current_id = trimmed[6..].trim().parse().unwrap_or(0);
                current_name.clear();
                current_desc.clear();
                current_vol = 100;
                current_mute = false;
                current_port = None;
            } else if trimmed.starts_with("Name: ") {
                current_name = trimmed[6..].trim().to_string();
            } else if trimmed.starts_with("Description: ") {
                current_desc = trimmed[13..].trim().to_string();
            } else if trimmed.starts_with("Mute: ") {
                current_mute = trimmed[6..].trim() == "yes";
            } else if trimmed.starts_with("Volume: ") {
                // Parse volume e.g. "front-left: 65536 / 100% / 0.00 dB"
                if let Some(pct_idx) = trimmed.find('%') {
                    if let Some(slash_idx) = trimmed[..pct_idx].rfind('/') {
                        let pct_str = trimmed[slash_idx + 1..pct_idx].trim();
                        current_vol = pct_str.parse().unwrap_or(100);
                    }
                }
            } else if trimmed.starts_with("Active Port: ") {
                current_port = Some(trimmed[13..].trim().to_string());
            }
        }

        if current_id != 0 {
            let is_bt = current_name.contains("bluez") || current_desc.to_lowercase().contains("bluetooth");
            let is_virt = current_name.contains("combine") || current_name.contains("Netra");
            let offset = self.latency_offsets.get(&current_id).copied().unwrap_or(0);
            let is_def = !default_sink_name.is_empty() && current_name == default_sink_name;

            sinks.push(AudioSink {
                id: current_id,
                name: current_name.clone(),
                description: if current_desc.is_empty() { current_name } else { current_desc },
                volume_percent: current_vol,
                is_muted: current_mute,
                is_default: is_def,
                is_bluetooth: is_bt,
                is_virtual: is_virt,
                latency_offset_ms: offset,
                active_port: current_port,
            });
        }

        Ok(sinks)
    }

    /// Queries active application audio playback streams
    pub fn get_streams(&self) -> Result<Vec<AudioStream>> {
        let output = Command::new("pactl")
            .args(["list", "sink-inputs"])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            return Ok(Vec::new());
        }

        let raw = String::from_utf8_lossy(&output.stdout);
        let mut streams = Vec::new();

        let mut current_id = 0u32;
        let mut current_sink = 0u32;
        let mut current_app = String::new();
        let mut current_bin = String::new();
        let mut current_vol = 100u8;
        let mut current_mute = false;

        for line in raw.lines() {
            let trimmed = line.trim();

            if trimmed.starts_with("Sink Input #") {
                if current_id != 0 {
                    let display_name = if !current_app.is_empty() {
                        current_app.clone()
                    } else if !current_bin.is_empty() {
                        current_bin.clone()
                    } else {
                        format!("Stream #{}", current_id)
                    };

                    streams.push(AudioStream {
                        id: current_id,
                        name: display_name.clone(),
                        app_name: display_name,
                        binary_name: current_bin.clone(),
                        current_sink_id: current_sink,
                        volume_percent: current_vol,
                        is_muted: current_mute,
                    });
                }

                current_id = trimmed[12..].trim().parse().unwrap_or(0);
                current_sink = 0;
                current_app.clear();
                current_bin.clear();
                current_vol = 100;
                current_mute = false;
            } else if trimmed.starts_with("Sink: ") {
                current_sink = trimmed[6..].trim().parse().unwrap_or(0);
            } else if trimmed.starts_with("Mute: ") {
                current_mute = trimmed[6..].trim() == "yes";
            } else if trimmed.starts_with("Volume: ") {
                if let Some(pct_idx) = trimmed.find('%') {
                    if let Some(slash_idx) = trimmed[..pct_idx].rfind('/') {
                        let pct_str = trimmed[slash_idx + 1..pct_idx].trim();
                        current_vol = pct_str.parse().unwrap_or(100);
                    }
                }
            } else if trimmed.starts_with("application.name = \"") {
                current_app = trimmed[20..trimmed.len() - 1].to_string();
            } else if trimmed.starts_with("application.process.binary = \"") {
                current_bin = trimmed[30..trimmed.len() - 1].to_string();
            }
        }

        if current_id != 0 {
            let display_name = if !current_app.is_empty() {
                current_app.clone()
            } else if !current_bin.is_empty() {
                current_bin.clone()
            } else {
                format!("Stream #{}", current_id)
            };

            streams.push(AudioStream {
                id: current_id,
                name: display_name.clone(),
                app_name: display_name,
                binary_name: current_bin,
                current_sink_id: current_sink,
                volume_percent: current_vol,
                is_muted: current_mute,
            });
        }

        Ok(streams)
    }

    /// Queries all physical and virtual audio sources (microphones / inputs) in PipeWire
    pub fn get_sources(&self) -> Result<Vec<AudioSource>> {
        let default_source_name = Command::new("pactl")
            .arg("get-default-source")
            .output()
            .ok()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or_default();

        let output = Command::new("pactl")
            .args(["list", "sources"])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            return Err(NetraError::DBus("Failed to list sources via pactl".into()));
        }

        let raw = String::from_utf8_lossy(&output.stdout);
        let mut sources = Vec::new();

        let mut current_id = 0u32;
        let mut current_name = String::new();
        let mut current_desc = String::new();
        let mut current_vol = 100u8;
        let mut current_mute = false;
        let mut current_port = None;
        let mut is_monitor = false;

        for line in raw.lines() {
            let trimmed = line.trim();

            if trimmed.starts_with("Source #") {
                if current_id != 0 {
                    let is_bt = current_name.contains("bluez") || current_desc.to_lowercase().contains("bluetooth");
                    let is_def = !default_source_name.is_empty() && current_name == default_source_name;

                    sources.push(AudioSource {
                        id: current_id,
                        name: current_name.clone(),
                        description: if current_desc.is_empty() { current_name.clone() } else { current_desc.clone() },
                        volume_percent: current_vol,
                        is_muted: current_mute,
                        is_default: is_def,
                        is_bluetooth: is_bt,
                        is_monitor,
                        active_port: current_port.clone(),
                    });
                }

                current_id = trimmed[8..].trim().parse().unwrap_or(0);
                current_name.clear();
                current_desc.clear();
                current_vol = 100;
                current_mute = false;
                current_port = None;
                is_monitor = false;
            } else if trimmed.starts_with("Name: ") {
                current_name = trimmed[6..].trim().to_string();
                if current_name.ends_with(".monitor") {
                    is_monitor = true;
                }
            } else if trimmed.starts_with("Description: ") {
                current_desc = trimmed[13..].trim().to_string();
            } else if trimmed.starts_with("Mute: ") {
                current_mute = trimmed[6..].trim() == "yes";
            } else if trimmed.starts_with("Volume: ") {
                if let Some(pct_idx) = trimmed.find('%') {
                    if let Some(slash_idx) = trimmed[..pct_idx].rfind('/') {
                        let pct_str = trimmed[slash_idx + 1..pct_idx].trim();
                        current_vol = pct_str.parse().unwrap_or(100);
                    }
                }
            } else if trimmed.starts_with("Active Port: ") {
                current_port = Some(trimmed[13..].trim().to_string());
            } else if trimmed.starts_with("Monitor of Sink: ") {
                if trimmed[17..].trim() != "n/a" {
                    is_monitor = true;
                }
            }
        }

        if current_id != 0 {
            let is_bt = current_name.contains("bluez") || current_desc.to_lowercase().contains("bluetooth");
            let is_def = !default_source_name.is_empty() && current_name == default_source_name;

            sources.push(AudioSource {
                id: current_id,
                name: current_name.clone(),
                description: if current_desc.is_empty() { current_name } else { current_desc },
                volume_percent: current_vol,
                is_muted: current_mute,
                is_default: is_def,
                is_bluetooth: is_bt,
                is_monitor,
                active_port: current_port,
            });
        }

        Ok(sources)
    }

    /// Queries active recording/capture streams from applications
    pub fn get_record_streams(&self) -> Result<Vec<AudioRecordStream>> {
        let output = Command::new("pactl")
            .args(["list", "source-outputs"])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            return Ok(Vec::new());
        }

        let raw = String::from_utf8_lossy(&output.stdout);
        let mut streams = Vec::new();

        let mut current_id = 0u32;
        let mut current_source = 0u32;
        let mut current_app = String::new();
        let mut current_bin = String::new();
        let mut current_vol = 100u8;
        let mut current_mute = false;

        for line in raw.lines() {
            let trimmed = line.trim();

            if trimmed.starts_with("Source Output #") {
                if current_id != 0 {
                    let display_name = if !current_app.is_empty() {
                        current_app.clone()
                    } else if !current_bin.is_empty() {
                        current_bin.clone()
                    } else {
                        format!("Recording #{}", current_id)
                    };

                    streams.push(AudioRecordStream {
                        id: current_id,
                        name: display_name.clone(),
                        app_name: display_name,
                        binary_name: current_bin.clone(),
                        current_source_id: current_source,
                        volume_percent: current_vol,
                        is_muted: current_mute,
                    });
                }

                current_id = trimmed[15..].trim().parse().unwrap_or(0);
                current_source = 0;
                current_app.clear();
                current_bin.clear();
                current_vol = 100;
                current_mute = false;
            } else if trimmed.starts_with("Source: ") {
                current_source = trimmed[8..].trim().parse().unwrap_or(0);
            } else if trimmed.starts_with("Mute: ") {
                current_mute = trimmed[6..].trim() == "yes";
            } else if trimmed.starts_with("Volume: ") {
                if let Some(pct_idx) = trimmed.find('%') {
                    if let Some(slash_idx) = trimmed[..pct_idx].rfind('/') {
                        let pct_str = trimmed[slash_idx + 1..pct_idx].trim();
                        current_vol = pct_str.parse().unwrap_or(100);
                    }
                }
            } else if trimmed.starts_with("application.name = \"") {
                current_app = trimmed[20..trimmed.len() - 1].to_string();
            } else if trimmed.starts_with("application.process.binary = \"") {
                current_bin = trimmed[30..trimmed.len() - 1].to_string();
            }
        }

        if current_id != 0 {
            let display_name = if !current_app.is_empty() {
                current_app.clone()
            } else if !current_bin.is_empty() {
                current_bin.clone()
            } else {
                format!("Recording #{}", current_id)
            };

            streams.push(AudioRecordStream {
                id: current_id,
                name: display_name.clone(),
                app_name: display_name,
                binary_name: current_bin,
                current_source_id: current_source,
                volume_percent: current_vol,
                is_muted: current_mute,
            });
        }

        Ok(streams)
    }

    /// Sets the volume of an audio input source / microphone (0-150%)
    pub fn set_source_volume(&self, source_id: u32, volume_percent: u8) -> Result<()> {
        let pct = volume_percent.clamp(0, 150);
        let output = Command::new("pactl")
            .args(["set-source-volume", &source_id.to_string(), &format!("{pct}%")])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            return Err(NetraError::DBus(format!("Failed to set source volume: {err}")));
        }
        Ok(())
    }

    /// Sets mute status for an audio input source / microphone
    pub fn set_source_mute(&self, source_id: u32, mute: bool) -> Result<()> {
        let mute_val = if mute { "1" } else { "0" };
        let output = Command::new("pactl")
            .args(["set-source-mute", &source_id.to_string(), mute_val])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            return Err(NetraError::DBus(format!("Failed to set source mute: {err}")));
        }
        Ok(())
    }

    /// Sets the default recording source / microphone in PipeWire
    pub fn set_default_source(&self, source_name: &str) -> Result<()> {
        info!("Setting default input source to: {}", source_name);
        let output = Command::new("pactl")
            .args(["set-default-source", source_name])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            return Err(NetraError::DBus(format!("Failed to set default source: {err}")));
        }
        Ok(())
    }

    /// Reroutes an application recording/capture stream to a specified source / microphone
    pub fn route_record_stream(&self, stream_id: u32, target_source_id: u32) -> Result<()> {
        info!("Moving recording stream #{} to source #{}", stream_id, target_source_id);
        let output = Command::new("pactl")
            .args(["move-source-output", &stream_id.to_string(), &target_source_id.to_string()])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            return Err(NetraError::DBus(format!("Failed to route recording stream: {err}")));
        }
        Ok(())
    }

    /// Sets the capture volume of an application recording stream
    pub fn set_record_stream_volume(&self, stream_id: u32, volume_percent: u8) -> Result<()> {
        let pct = volume_percent.clamp(0, 150);
        let output = Command::new("pactl")
            .args(["set-source-output-volume", &stream_id.to_string(), &format!("{pct}%")])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            return Err(NetraError::DBus(format!("Failed to set recording stream volume: {err}")));
        }
        Ok(())
    }

    /// Mutes/unmutes an application recording stream
    pub fn set_record_stream_mute(&self, stream_id: u32, mute: bool) -> Result<()> {
        let mute_val = if mute { "1" } else { "0" };
        let output = Command::new("pactl")
            .args(["set-source-output-mute", &stream_id.to_string(), mute_val])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            return Err(NetraError::DBus(format!("Failed to set recording stream mute: {err}")));
        }
        Ok(())
    }

    /// Reroutes an application playback stream to a specified sink
    pub fn route_stream(&self, stream_id: u32, target_sink_id: u32) -> Result<()> {
        info!("Moving stream #{} to sink #{}", stream_id, target_sink_id);
        let output = Command::new("pactl")
            .args(["move-sink-input", &stream_id.to_string(), &target_sink_id.to_string()])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            error!("Failed to route audio stream: {}", err);
            return Err(NetraError::DBus(format!("move-sink-input failed: {err}")));
        }

        Ok(())
    }

    /// Changes volume percentage of a sink
    pub fn set_sink_volume(&self, sink_id: u32, volume_percent: u8) -> Result<()> {
        info!("Setting sink #{} volume to {}%", sink_id, volume_percent);
        let output = Command::new("pactl")
            .args(["set-sink-volume", &sink_id.to_string(), &format!("{}%", volume_percent)])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            return Err(NetraError::DBus(format!("set-sink-volume failed: {err}")));
        }

        Ok(())
    }

    /// Toggles or sets sink mute state
    pub fn set_sink_mute(&self, sink_id: u32, is_muted: bool) -> Result<()> {
        let flag = if is_muted { "1" } else { "0" };
        let output = Command::new("pactl")
            .args(["set-sink-mute", &sink_id.to_string(), flag])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            return Err(NetraError::DBus(format!("set-sink-mute failed: {err}")));
        }

        Ok(())
    }

    /// Adjusts latency compensation offset in milliseconds (for syncing dual headphones)
    pub fn set_sink_latency_offset(&mut self, sink_id: u32, offset_ms: i32) -> Result<()> {
        info!("Setting latency offset on sink #{} to {}ms", sink_id, offset_ms);
        self.latency_offsets.insert(sink_id, offset_ms);

        // Convert ms to microseconds for PipeWire / PulseAudio
        let offset_micros = offset_ms * 1000;
        let _ = Command::new("pactl")
            .args(["set-sink-port-latency-offset", &sink_id.to_string(), "analog-output", &offset_micros.to_string()])
            .output();

        Ok(())
    }

    /// Creates a synchronized virtual multi-sink that broadcasts audio across multiple physical sinks
    pub fn create_multi_sink(&mut self, group_name: &str, slave_names: &[String]) -> Result<u32> {
        let mut target_slaves: Vec<String> = slave_names.to_vec();

        // If no slaves explicitly provided, automatically gather all active Bluetooth audio sinks
        if target_slaves.is_empty() {
            if let Ok(sinks) = self.get_sinks() {
                let bt_sinks: Vec<String> = sinks
                    .into_iter()
                    .filter(|s| !s.is_virtual && s.is_bluetooth)
                    .map(|s| s.name)
                    .collect();
                if !bt_sinks.is_empty() {
                    target_slaves = bt_sinks;
                }
            }
        }

        if target_slaves.is_empty() {
            return Err(NetraError::DBus("No audio sinks available for multi-sink".into()));
        }

        // Store previous default sink before switching
        if self.previous_default_sink.is_none() {
            if let Ok(out) = Command::new("pactl").arg("get-default-sink").output() {
                if out.status.success() {
                    let cur = String::from_utf8_lossy(&out.stdout).trim().to_string();
                    if !cur.is_empty() && !cur.contains("NetraGroup_") {
                        self.previous_default_sink = Some(cur);
                    }
                }
            }
        }

        let slaves_arg = target_slaves.join(",");
        let sink_name = format!("NetraGroup_{}", group_name.replace(' ', "_"));
        let desc_arg = format!("Netra Dual Audio ({})", group_name);

        info!("Creating PipeWire combine-sink '{}' with slaves: {}", sink_name, slaves_arg);

        let output = Command::new("pactl")
            .args([
                "load-module",
                "module-combine-sink",
                &format!("sink_name={}", sink_name),
                &format!("slaves={}", slaves_arg),
                &format!("sink_properties=device.description=\"{}\"", desc_arg),
            ])
            .output()
            .map_err(|e| NetraError::Io(e))?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            error!("Failed to load module-combine-sink: {}", err);
            return Err(NetraError::DBus(format!("create_multi_sink failed: {err}")));
        }

        let module_id_str = String::from_utf8_lossy(&output.stdout).trim().to_string();
        let module_id: u32 = module_id_str.parse().unwrap_or(0);

        self.active_multi_sinks.insert(group_name.to_string(), module_id);
        info!("Multi-sink created with module ID: {}", module_id);

        // Set as default sink so system sound streams to both devices immediately
        let _ = Command::new("pactl")
            .args(["set-default-sink", &sink_name])
            .output();

        // Move all active playback streams into the new combine-sink
        if let Ok(streams) = self.get_streams() {
            for s in streams {
                let _ = Command::new("pactl")
                    .args(["move-sink-input", &s.id.to_string(), &sink_name])
                    .output();
            }
        }

        Ok(module_id)
    }

    /// Tears down a virtual multi-sink group and restores default sink
    pub fn destroy_multi_sink(&mut self, group_name: &str) -> Result<()> {
        let target_module = self.active_multi_sinks.remove(group_name)
            .or_else(|| self.active_multi_sinks.drain().next().map(|(_, v)| v));

        if let Some(module_id) = target_module {
            info!("Unloading multi-sink module ID: {}", module_id);
            let _ = Command::new("pactl")
                .args(["unload-module", &module_id.to_string()])
                .output();
        }

        // Restore previous default sink if all multi sinks removed
        if self.active_multi_sinks.is_empty() {
            if let Some(prev) = self.previous_default_sink.take() {
                info!("Restoring previous default audio sink: {}", prev);
                let _ = Command::new("pactl")
                    .args(["set-default-sink", &prev])
                    .output();
            }
        }

        Ok(())
    }

    /// Tears down any residual Netra combine sinks
    pub fn cleanup_all_multi_sinks(&mut self) {
        if let Ok(out) = Command::new("pactl").args(["list", "modules", "short"]).output() {
            let text = String::from_utf8_lossy(&out.stdout);
            for line in text.lines() {
                if line.contains("NetraGroup_") {
                    if let Some(mod_id) = line.split_whitespace().next() {
                        let _ = Command::new("pactl").args(["unload-module", mod_id]).output();
                    }
                }
            }
        }
        self.active_multi_sinks.clear();
        if let Some(prev) = self.previous_default_sink.take() {
            let _ = Command::new("pactl").args(["set-default-sink", &prev]).output();
        }
    }
}
