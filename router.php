<?php
declare(strict_types=1);

$state = getenv('STATE_DIR') ?: '/state';

function read_or(string $path, string $default = ''): string {
    return is_readable($path) ? trim((string)file_get_contents($path)) : $default;
}

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';

if ($path !== '/status' && $path !== '/cgi-bin/status') {
    http_response_code(404);
    header('Content-Type: application/json');
    echo json_encode(['error' => 'not found']), "\n";
    return true;
}

$startIso   = read_or($state . '/last_start', 'unknown');
$startEpoch = read_or($state . '/last_start_epoch', '0');
$stopIso    = read_or($state . '/last_stop', '');
$exitCode   = read_or($state . '/last_exit', '');

if (!ctype_digit($startEpoch)) {
    $startEpoch = '0';
}
$uptime = max(0, time() - (int)$startEpoch);

$lines  = null;
if (isset($_GET['lines']) && preg_match('/^\d+$/', (string)$_GET['lines'])) {
    $lines = (int)$_GET['lines'];
}

$output  = '';
$logPath = $state . '/last_run.log';
if (is_readable($logPath)) {
    if ($lines !== null && $lines > 0) {
        // Last N lines without shelling out to `tail`.
        $fh = fopen($logPath, 'r');
        if ($fh !== false) {
            $buf = [];
            while (($line = fgets($fh)) !== false) {
                $buf[] = $line;
                if (count($buf) > $lines) {
                    array_shift($buf);
                }
            }
            fclose($fh);
            $output = implode('', $buf);
        }
    } else {
        $output = (string)file_get_contents($logPath);
    }
}

$payload = [
    'last_restart_utc' => $startIso,
    'uptime_seconds'   => $uptime,
    'last_stop_utc'    => $stopIso,
    'last_exit_code'   => $exitCode,
    'output'           => $output,
];

header('Content-Type: application/json');
header('Cache-Control: no-store');
echo json_encode(
    $payload,
    JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT
), "\n";

return true;
