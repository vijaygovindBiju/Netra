use netra_audio::PipeWireAudioEngine;
use netra_bluetooth::BluezClient;
use netra_common::models::hotspot::{HotspotConfig, HotspotStatus, QoSPriority};
use netra_common::models::network::WifiBand;
use netra_network::NetworkEngine;
use netra_traffic::{SocketScanner, TrafficControlQoS};
use std::sync::Arc;
use tokio::sync::Mutex;
use tracing::{info, Level};
use tracing_subscriber::FmtSubscriber;
use zbus::connection::Builder;

// 1. Network D-Bus Interface
struct NetworkInterface {
    engine: Arc<Mutex<NetworkEngine>>,
}

#[zbus::interface(name = "org.netra.Network")]
impl NetworkInterface {
    async fn scan_wifi(&self) -> zbus::fdo::Result<()> {
        info!("D-Bus: Requesting Wi-Fi scan");
        let engine = self.engine.lock().await;
        engine
            .scan_wifi()
            .await
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn get_access_points_json(&self) -> zbus::fdo::Result<String> {
        let engine = self.engine.lock().await;
        let aps = engine
            .get_access_points()
            .await
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))?;
        serde_json::to_string(&aps).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn connect_wifi(&self, ssid: &str, passphrase: &str) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Connecting to Wi-Fi SSID: {}", ssid);
        let engine = self.engine.lock().await;
        engine
            .connect_wifi(ssid, passphrase)
            .await
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn disconnect_wifi(&self) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Disconnecting Wi-Fi");
        let engine = self.engine.lock().await;
        engine
            .disconnect_wifi()
            .await
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn get_interface_metrics_json(&self) -> zbus::fdo::Result<String> {
        let mut engine = self.engine.lock().await;
        let metrics = engine
            .get_interface_metrics()
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))?;
        serde_json::to_string(&metrics).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn get_primary_interface(&self) -> String {
        let engine = self.engine.lock().await;
        engine.get_primary_interface_name().unwrap_or_default()
    }
}

// 2. Hotspot D-Bus Interface
struct HotspotInterface {
    engine: Arc<Mutex<NetworkEngine>>,
}

#[zbus::interface(name = "org.netra.Hotspot")]
impl HotspotInterface {
    async fn start_hotspot(
        &self,
        ssid: &str,
        passphrase: &str,
        band: &str,
    ) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Starting Hotspot SSID: '{}' on band: '{}'", ssid, band);
        let mut engine = self.engine.lock().await;
        let wifi_band = match band {
            "5GHz" => WifiBand::Band5GHz,
            _ => WifiBand::Band24GHz,
        };
        let config = HotspotConfig {
            ssid: ssid.to_string(),
            passphrase: passphrase.to_string(),
            band: wifi_band,
            channel: None,
            ap_isolate: false,
        };
        engine
            .start_hotspot(config)
            .await
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn stop_hotspot(&self) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Stopping Hotspot");
        let mut engine = self.engine.lock().await;
        engine
            .stop_hotspot()
            .await
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn is_active(&self) -> bool {
        let engine = self.engine.lock().await;
        engine.get_hotspot_status() == HotspotStatus::Active
    }

    async fn get_hotspot_status(&self) -> String {
        let engine = self.engine.lock().await;
        match engine.get_hotspot_status() {
            HotspotStatus::Active => "Active".to_string(),
            HotspotStatus::Starting => "Starting".to_string(),
            HotspotStatus::Stopping => "Stopping".to_string(),
            HotspotStatus::Failed(e) => format!("Failed: {e}"),
            HotspotStatus::Inactive => "Inactive".to_string(),
        }
    }

    async fn get_connected_clients_json(&self) -> zbus::fdo::Result<String> {
        let mut engine = self.engine.lock().await;
        let clients = engine
            .get_connected_clients()
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))?;
        serde_json::to_string(&clients).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn set_client_priority(&self, mac: &str, priority: &str) -> zbus::fdo::Result<bool> {
        let mut engine = self.engine.lock().await;
        engine.set_client_priority(mac, QoSPriority::from_str(priority));
        Ok(true)
    }
}

// 3. Bluetooth D-Bus Interface
struct BluetoothInterface {
    client: Arc<Mutex<Option<BluezClient>>>,
}

#[zbus::interface(name = "org.netra.Bluetooth")]
impl BluetoothInterface {
    async fn start_discovery(&self) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Starting Bluetooth discovery");
        let guard = self.client.lock().await;
        if let Some(ref client) = *guard {
            client.start_discovery().await.map(|_| true).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
        } else {
            Err(zbus::fdo::Error::Failed("Bluetooth not initialized".into()))
        }
    }

    async fn stop_discovery(&self) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Stopping Bluetooth discovery");
        let guard = self.client.lock().await;
        if let Some(ref client) = *guard {
            client.stop_discovery().await.map(|_| true).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
        } else {
            Err(zbus::fdo::Error::Failed("Bluetooth not initialized".into()))
        }
    }

    async fn get_adapter_info_json(&self) -> zbus::fdo::Result<String> {
        let guard = self.client.lock().await;
        if let Some(ref client) = *guard {
            let info = client.get_adapter_info().await.map_err(|e| zbus::fdo::Error::Failed(e.to_string()))?;
            serde_json::to_string(&info).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
        } else {
            Err(zbus::fdo::Error::Failed("Bluetooth adapter not found".into()))
        }
    }

    async fn get_devices_json(&self) -> zbus::fdo::Result<String> {
        let guard = self.client.lock().await;
        if let Some(ref client) = *guard {
            let devices = client.get_devices().await.map_err(|e| zbus::fdo::Error::Failed(e.to_string()))?;
            serde_json::to_string(&devices).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
        } else {
            Ok("[]".to_string())
        }
    }

    async fn connect_device(&self, address: &str) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Connect Bluetooth device: {}", address);
        let guard = self.client.lock().await;
        if let Some(ref client) = *guard {
            client.connect_device(address).await.map(|_| true).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
        } else {
            Err(zbus::fdo::Error::Failed("Bluetooth not initialized".into()))
        }
    }

    async fn disconnect_device(&self, address: &str) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Disconnect Bluetooth device: {}", address);
        let guard = self.client.lock().await;
        if let Some(ref client) = *guard {
            client.disconnect_device(address).await.map(|_| true).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
        } else {
            Err(zbus::fdo::Error::Failed("Bluetooth not initialized".into()))
        }
    }

    async fn pair_device(&self, address: &str) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Pair Bluetooth device: {}", address);
        let guard = self.client.lock().await;
        if let Some(ref client) = *guard {
            client.pair_device(address).await.map(|_| true).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
        } else {
            Err(zbus::fdo::Error::Failed("Bluetooth not initialized".into()))
        }
    }

    async fn remove_device(&self, address: &str) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Remove Bluetooth device: {}", address);
        let guard = self.client.lock().await;
        if let Some(ref client) = *guard {
            client.remove_device(address).await.map(|_| true).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
        } else {
            Err(zbus::fdo::Error::Failed("Bluetooth not initialized".into()))
        }
    }
}

// 4. Traffic & QoS D-Bus Interface
struct TrafficInterface {
    scanner: Arc<Mutex<SocketScanner>>,
}

#[zbus::interface(name = "org.netra.Traffic")]
impl TrafficInterface {
    async fn get_process_traffic_json(&self) -> zbus::fdo::Result<String> {
        let mut scanner = self.scanner.lock().await;
        let entries = scanner.scan_process_traffic().map_err(|e| zbus::fdo::Error::Failed(e.to_string()))?;
        serde_json::to_string(&entries).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn init_qos(&self, iface: &str) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Initializing QoS on {}", iface);
        TrafficControlQoS::init_interface_htb(iface)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn assign_ip_priority(&self, iface: &str, ip: &str, priority: &str) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Assigning QoS priority '{}' to IP {} on {}", priority, ip, iface);
        TrafficControlQoS::assign_ip_priority(iface, ip, priority)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn reset_qos(&self, iface: &str) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Resetting QoS on {}", iface);
        TrafficControlQoS::reset_interface(iface)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }
}

// 5. PipeWire Audio D-Bus Interface
struct AudioInterface {
    engine: Arc<Mutex<PipeWireAudioEngine>>,
}

#[zbus::interface(name = "org.netra.Audio")]
impl AudioInterface {
    async fn get_sinks_json(&self) -> zbus::fdo::Result<String> {
        let engine = self.engine.lock().await;
        let sinks = engine.get_sinks().map_err(|e| zbus::fdo::Error::Failed(e.to_string()))?;
        serde_json::to_string(&sinks).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn get_streams_json(&self) -> zbus::fdo::Result<String> {
        let engine = self.engine.lock().await;
        let streams = engine.get_streams().map_err(|e| zbus::fdo::Error::Failed(e.to_string()))?;
        serde_json::to_string(&streams).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn get_sources_json(&self) -> zbus::fdo::Result<String> {
        let engine = self.engine.lock().await;
        let sources = engine.get_sources().map_err(|e| zbus::fdo::Error::Failed(e.to_string()))?;
        serde_json::to_string(&sources).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn get_record_streams_json(&self) -> zbus::fdo::Result<String> {
        let engine = self.engine.lock().await;
        let streams = engine.get_record_streams().map_err(|e| zbus::fdo::Error::Failed(e.to_string()))?;
        serde_json::to_string(&streams).map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn set_source_volume(&self, source_id: u32, volume_percent: u8) -> zbus::fdo::Result<bool> {
        let engine = self.engine.lock().await;
        engine.set_source_volume(source_id, volume_percent)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn set_source_mute(&self, source_id: u32, is_muted: bool) -> zbus::fdo::Result<bool> {
        let engine = self.engine.lock().await;
        engine.set_source_mute(source_id, is_muted)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn set_default_source(&self, source_name: &str) -> zbus::fdo::Result<bool> {
        let engine = self.engine.lock().await;
        engine.set_default_source(source_name)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn route_record_stream(&self, stream_id: u32, target_source_id: u32) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Routing recording stream #{} to source #{}", stream_id, target_source_id);
        let engine = self.engine.lock().await;
        engine.route_record_stream(stream_id, target_source_id)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn set_record_stream_volume(&self, stream_id: u32, volume_percent: u8) -> zbus::fdo::Result<bool> {
        let engine = self.engine.lock().await;
        engine.set_record_stream_volume(stream_id, volume_percent)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn set_record_stream_mute(&self, stream_id: u32, is_muted: bool) -> zbus::fdo::Result<bool> {
        let engine = self.engine.lock().await;
        engine.set_record_stream_mute(stream_id, is_muted)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn route_stream(&self, stream_id: u32, target_sink_id: u32) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Routing audio stream #{} to sink #{}", stream_id, target_sink_id);
        let engine = self.engine.lock().await;
        engine.route_stream(stream_id, target_sink_id)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn set_sink_volume(&self, sink_id: u32, volume_percent: u8) -> zbus::fdo::Result<bool> {
        let engine = self.engine.lock().await;
        engine.set_sink_volume(sink_id, volume_percent)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn set_sink_mute(&self, sink_id: u32, is_muted: bool) -> zbus::fdo::Result<bool> {
        let engine = self.engine.lock().await;
        engine.set_sink_mute(sink_id, is_muted)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn set_sink_latency_offset(&self, sink_id: u32, offset_ms: i32) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Setting sink #{} latency offset to {}ms", sink_id, offset_ms);
        let mut engine = self.engine.lock().await;
        engine.set_sink_latency_offset(sink_id, offset_ms)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn create_multi_sink(&self, group_name: &str, slave_names_json: &str) -> zbus::fdo::Result<u32> {
        info!("D-Bus: Creating multi-sink group '{}'", group_name);
        let slave_names: Vec<String> = serde_json::from_str(slave_names_json)
            .map_err(|e| zbus::fdo::Error::Failed(format!("Invalid slaves JSON: {e}")))?;

        let mut engine = self.engine.lock().await;
        engine.create_multi_sink(group_name, &slave_names)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }

    async fn destroy_multi_sink(&self, group_name: &str) -> zbus::fdo::Result<bool> {
        info!("D-Bus: Destroying multi-sink group '{}'", group_name);
        let mut engine = self.engine.lock().await;
        engine.destroy_multi_sink(group_name)
            .map(|_| true)
            .map_err(|e| zbus::fdo::Error::Failed(e.to_string()))
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let subscriber = FmtSubscriber::builder()
        .with_max_level(Level::DEBUG)
        .finish();
    tracing::subscriber::set_global_default(subscriber)?;

    info!("Starting Netra Daemon (netrad) v1.0.0-full...");

    // Initialize Subsystems
    let net_engine = Arc::new(Mutex::new(NetworkEngine::new().await?));
    let bt_client = Arc::new(Mutex::new(BluezClient::new().await.ok()));
    let traffic_scanner = Arc::new(Mutex::new(SocketScanner::new()));
    let audio_engine = Arc::new(Mutex::new(PipeWireAudioEngine::new()));

    let network_iface = NetworkInterface {
        engine: Arc::clone(&net_engine),
    };
    let hotspot_iface = HotspotInterface {
        engine: Arc::clone(&net_engine),
    };
    let bt_iface = BluetoothInterface {
        client: Arc::clone(&bt_client),
    };
    let traffic_iface = TrafficInterface {
        scanner: Arc::clone(&traffic_scanner),
    };
    let audio_iface = AudioInterface {
        engine: Arc::clone(&audio_engine),
    };

    // Try System Bus first, fallback to Session Bus for local user development
    let _connection = match Builder::system() {
        Ok(builder) => {
            info!("Attempting connection to D-Bus System Bus...");
            match builder
                .name("org.netra.Control")?
                .serve_at("/org/netra/Network", network_iface)?
                .serve_at("/org/netra/Hotspot", hotspot_iface)?
                .serve_at("/org/netra/Bluetooth", bt_iface)?
                .serve_at("/org/netra/Traffic", traffic_iface)?
                .serve_at("/org/netra/Audio", audio_iface)?
                .build()
                .await
            {
                Ok(conn) => {
                    info!("Successfully registered 'org.netra.Control' with ALL 5 interfaces on System Bus!");
                    conn
                }
                Err(err) => {
                    info!(
                        "System bus registration failed ({err}). Falling back to Session Bus for local development...",
                    );
                    let net_i = NetworkInterface { engine: Arc::clone(&net_engine) };
                    let hs_i = HotspotInterface { engine: Arc::clone(&net_engine) };
                    let bt_i = BluetoothInterface { client: Arc::clone(&bt_client) };
                    let tr_i = TrafficInterface { scanner: Arc::clone(&traffic_scanner) };
                    let au_i = AudioInterface { engine: Arc::clone(&audio_engine) };

                    Builder::session()?
                        .name("org.netra.Control")?
                        .serve_at("/org/netra/Network", net_i)?
                        .serve_at("/org/netra/Hotspot", hs_i)?
                        .serve_at("/org/netra/Bluetooth", bt_i)?
                        .serve_at("/org/netra/Traffic", tr_i)?
                        .serve_at("/org/netra/Audio", au_i)?
                        .build()
                        .await?
                }
            }
        }
        Err(_) => {
            let net_i = NetworkInterface { engine: Arc::clone(&net_engine) };
            let hs_i = HotspotInterface { engine: Arc::clone(&net_engine) };
            let bt_i = BluetoothInterface { client: Arc::clone(&bt_client) };
            let tr_i = TrafficInterface { scanner: Arc::clone(&traffic_scanner) };
            let au_i = AudioInterface { engine: Arc::clone(&audio_engine) };

            Builder::session()?
                .name("org.netra.Control")?
                .serve_at("/org/netra/Network", net_i)?
                .serve_at("/org/netra/Hotspot", hs_i)?
                .serve_at("/org/netra/Bluetooth", bt_i)?
                .serve_at("/org/netra/Traffic", tr_i)?
                .serve_at("/org/netra/Audio", au_i)?
                .build()
                .await?
        }
    };

    info!("Netra Full Daemon is running with Wi-Fi, Hotspot, Bluetooth, Traffic, and Audio engines listening.");

    // Keep service running
    std::future::pending::<()>().await;

    Ok(())
}
