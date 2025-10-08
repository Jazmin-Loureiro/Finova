<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Panel Admin - Usuarios</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="p-4">
  <div class="container">
    <h1>Usuarios registrados</h1>

    @if(session('success'))
      <div class="alert alert-success">{{ session('success') }}</div>
    @endif

    <h3 class="mt-4">Todos los usuarios</h3>
    <table class="table table-striped mt-2">
      <thead>
        <tr>
          <th>ID</th>
          <th>Nombre</th>
          <th>Email</th>
          <th>Estado</th>
          <th>Acción</th>
        </tr>
      </thead>
      <tbody>
        @foreach($users as $user)
          <tr>
            <td>{{ $user->id }}</td>
            <td>{{ $user->name }}</td>
            <td>{{ $user->email }}</td>
            <td>
              @if($user->active)
                <span class="badge bg-success">Activo</span>
              @else
                <span class="badge bg-danger">Inactivo</span>
              @endif
            </td>
            <td>
              @if(!$user->active)
                <form method="POST" action="{{ route('admin.users.activate', $user->id) }}" style="display:inline;">
                  @csrf
                  <button class="btn btn-sm btn-success">Reactivar</button>
                </form>
              @else
                <form method="POST" action="{{ route('admin.users.deactivate', $user->id) }}" style="display:inline;">
                  @csrf
                  <button class="btn btn-sm btn-danger">Dar de baja</button>
                </form>
              @endif
            </td>
          </tr>
        @endforeach
      </tbody>
    </table>

    <h3 class="mt-5">Solicitudes de reactivación pendientes</h3>
    <table class="table table-bordered mt-2">
      <thead class="table-light">
        <tr>
          <th>ID</th>
          <th>Email del usuario</th>
          <th>Fecha de solicitud</th>
        </tr>
      </thead>
      <tbody>
        @forelse($requests as $req)
          <tr>
            <td>{{ $req->id }}</td>
            <td>{{ $req->user->email }}</td>
            <td>{{ $req->requested_at }}</td>
          </tr>
        @empty
          <tr>
            <td colspan="3" class="text-center">No hay solicitudes pendientes</td>
          </tr>
        @endforelse
      </tbody>
    </table>
  </div>
</body>
</html>
