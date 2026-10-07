pub fn lookup_vendor(mac: &str) -> Option<&'static str> {
    let clean = mac.replace([':', '-'], "").to_uppercase();
    if clean.len() < 6 {
        return None;
    }
    let prefix = &clean[0..6];

    match prefix {
        // Apple
        "F0D5BF" | "ACDE48" | "BC9FEF" | "A483E7" | "DCF505" | "F437B7" | "0017F2" | "40A6D9" | "705681" => Some("Apple"),
        // Samsung
        "50C8E5" | "A8798D" | "702C1F" | "342387" | "D0176A" | "549963" | "B072BF" | "641CB0" | "88366C" => Some("Samsung"),
        // Google
        "A47733" | "F4F5DB" | "24F5AA" | "3C5AB4" | "546009" | "747548" | "D83C69" => Some("Google"),
        // Intel
        "14B5CD" | "001B21" | "001E64" | "00216A" | "002314" | "0024D7" | "0026C7" | "3413E8" | "8086F2" => Some("Intel"),
        // Xiaomi
        "640980" | "7C49EB" | "186590" | "286C07" | "7811DC" | "ACF7F3" => Some("Xiaomi"),
        // OnePlus / Oppo
        "94652D" | "9C7142" | "AC83F3" | "E4FAED" => Some("OnePlus/Oppo"),
        // Espressif (IoT / Smart Home)
        "240AC4" | "30AEA4" | "A020A6" | "840D8E" | "483FDA" | "3C6105" => Some("Espressif IoT"),
        // TP-Link
        "50C7BF" | "60634C" | "E848B8" | "B04E26" | "D807B6" => Some("TP-Link"),
        // Sony
        "0013A9" | "0015C1" | "001D28" | "001E4C" | "00248D" => Some("Sony"),
        // Dell
        "001422" | "00188B" | "001E4F" | "00219B" | "002219" => Some("Dell"),
        // Microsoft
        "00155D" | "281878" | "7C1E52" | "DC5360" => Some("Microsoft"),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_lookup_vendor() {
        assert_eq!(lookup_vendor("F0:D5:BF:11:22:33"), Some("Apple"));
        assert_eq!(lookup_vendor("50-C8-E5-AA-BB-CC"), Some("Samsung"));
        assert_eq!(lookup_vendor("14:b5:cd:eb:fb:ad"), Some("Intel"));
        assert_eq!(lookup_vendor("00:00:00:00:00:00"), None);
    }
}
