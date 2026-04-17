<?php
// api.php — REST API Endpoint
// Handles GET / POST / PUT / DELETE for inventory items.
// All responses are JSON.

require_once 'db.php';

// Allow cross-origin requests (helpful during local dev)
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$pdo    = getDB();
$method = $_SERVER['REQUEST_METHOD'];

// Helper: send JSON response
function respond(int $code, mixed $data): void {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit;
}

// Helper: read JSON body
function jsonBody(): array {
    $raw = file_get_contents('php://input');
    return $raw ? (json_decode($raw, true) ?? []) : [];
}

// Helper: validate item fields
function validateItem(array $data): ?string {
    if (empty($data['name']) || !is_string($data['name'])) return 'name is required.';
    if (!isset($data['quantity']) || !is_numeric($data['quantity']) || (int)$data['quantity'] < 0) return 'quantity must be a non-negative integer.';
    if (!isset($data['price'])    || !is_numeric($data['price'])    || (float)$data['price'] < 0)  return 'price must be a non-negative number.';
    return null;
}

// ──────────────────────────────────────────────────────────
// Route: GET /api.php             → list all items
// Route: GET /api.php?id=N        → single item
// Route: GET /api.php?search=XYZ  → search by name
// ──────────────────────────────────────────────────────────
if ($method === 'GET') {
    if (!empty($_GET['id'])) {
        $stmt = $pdo->prepare('SELECT * FROM items WHERE id = ?');
        $stmt->execute([(int)$_GET['id']]);
        $item = $stmt->fetch();
        if (!$item) respond(404, ['error' => 'Item not found.']);
        respond(200, $item);
    }

    if (!empty($_GET['search'])) {
        $like = '%' . $_GET['search'] . '%';
        $stmt = $pdo->prepare('SELECT * FROM items WHERE name LIKE ? ORDER BY name ASC');
        $stmt->execute([$like]);
        respond(200, $stmt->fetchAll());
    }

    // Summary report endpoint
    if (isset($_GET['report'])) {
        $row = $pdo->query('SELECT COUNT(*) AS total_items, COALESCE(SUM(quantity * price), 0) AS total_value FROM items')->fetch();
        respond(200, [
            'total_items' => (int)$row['total_items'],
            'total_value' => (float)$row['total_value'],
        ]);
    }

    // All items
    $stmt = $pdo->query('SELECT * FROM items ORDER BY id ASC');
    respond(200, $stmt->fetchAll());
}

// ──────────────────────────────────────────────────────────
// Route: POST /api.php  → create new item
// Body: { "name": "...", "quantity": N, "price": N }
// ──────────────────────────────────────────────────────────
if ($method === 'POST') {
    $data = jsonBody();
    $err  = validateItem($data);
    if ($err) respond(400, ['error' => $err]);

    $stmt = $pdo->prepare('INSERT INTO items (name, quantity, price) VALUES (?, ?, ?)');
    $stmt->execute([
        trim($data['name']),
        (int)$data['quantity'],
        round((float)$data['price'], 2),
    ]);

    $newId = (int)$pdo->lastInsertId();
    $stmt  = $pdo->prepare('SELECT * FROM items WHERE id = ?');
    $stmt->execute([$newId]);
    respond(201, $stmt->fetch());
}

// ──────────────────────────────────────────────────────────
// Route: PUT /api.php?id=N  → update existing item
// Body: { "name": "...", "quantity": N, "price": N }
// ──────────────────────────────────────────────────────────
if ($method === 'PUT') {
    if (empty($_GET['id'])) respond(400, ['error' => 'id parameter required.']);
    $id = (int)$_GET['id'];

    // Check exists
    $check = $pdo->prepare('SELECT id FROM items WHERE id = ?');
    $check->execute([$id]);
    if (!$check->fetch()) respond(404, ['error' => 'Item not found.']);

    $data = jsonBody();
    $err  = validateItem($data);
    if ($err) respond(400, ['error' => $err]);

    $stmt = $pdo->prepare('UPDATE items SET name = ?, quantity = ?, price = ? WHERE id = ?');
    $stmt->execute([
        trim($data['name']),
        (int)$data['quantity'],
        round((float)$data['price'], 2),
        $id,
    ]);

    $stmt = $pdo->prepare('SELECT * FROM items WHERE id = ?');
    $stmt->execute([$id]);
    respond(200, $stmt->fetch());
}

// ──────────────────────────────────────────────────────────
// Route: DELETE /api.php?id=N  → delete item
// ──────────────────────────────────────────────────────────
if ($method === 'DELETE') {
    if (empty($_GET['id'])) respond(400, ['error' => 'id parameter required.']);
    $id = (int)$_GET['id'];

    $check = $pdo->prepare('SELECT id FROM items WHERE id = ?');
    $check->execute([$id]);
    if (!$check->fetch()) respond(404, ['error' => 'Item not found.']);

    $pdo->prepare('DELETE FROM items WHERE id = ?')->execute([$id]);
    respond(200, ['message' => 'Item deleted.', 'id' => $id]);
}

respond(405, ['error' => 'Method not allowed.']);
