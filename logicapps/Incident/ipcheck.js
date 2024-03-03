// Process the alert data and remove internal owned IPs
function isIPInRange(ip, base, mask) {
    const [ipA, ipB, ipC, ipD] = ip.split('.').map(Number);
    const [baseA, baseB, baseC, baseD] = base.split('.').map(Number);
    const ipBinary = (ipA << 24) + (ipB << 16) + (ipC << 8) + ipD;
    const baseBinary = (baseA << 24) + (baseB << 16) + (baseC << 8) + baseD;
    return (ipBinary & (-1 << (32 - mask))) === baseBinary;
}
function isPrivateOrSpecifiedIP(ip) {
    // Check for private IP ranges
    // You can add additional ranges here and update the logic app
    if (isIPInRange(ip, "10.0.0.0", 8) ||
        isIPInRange(ip, "172.16.0.0", 12) ||
        isIPInRange(ip, "192.168.0.0", 16) ||
        isIPInRange(ip, "199.247.0.0", 16)) {
        return true;
    }
    return false;
}
let alert = workflowContext.actions['Compose']['outputs'][0]['value'][0];
if (isPrivateOrSpecifiedIP(alert['SourceIP'])) {
    return null;
}
return alert;