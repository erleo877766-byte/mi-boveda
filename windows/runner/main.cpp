#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Ensure only a single instance runs at a time. Multiple instances corrupt
  // the wallet database (hive lock conflicts), which leaves the window hidden.
  HANDLE single_instance_mutex =
      CreateMutexW(nullptr, FALSE, L"MiBovedaSingleInstance");
  if (single_instance_mutex != nullptr &&
      GetLastError() == ERROR_ALREADY_EXISTS) {
    CloseHandle(single_instance_mutex);
    return EXIT_SUCCESS;
  }

  // Force software rendering (WARP). Some machines (old Intel GPUs) crash in
  // dcomp.dll while compositing and stop drawing icons/images. Software
  // rendering keeps the UI stable and complete on those machines.
  ::SetEnvironmentVariableW(L"ANGLE_DEFAULT_PLATFORM", L"warp");

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Mi B\x00F3veda", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
