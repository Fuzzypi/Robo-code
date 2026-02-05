use tauri::Manager;
use tauri_plugin_shell::ShellExt;
use std::sync::{Arc, Mutex};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  // Arc<Mutex> to hold the API server process
  let api_process: Arc<Mutex<Option<tauri_plugin_shell::process::CommandChild>>> = Arc::new(Mutex::new(None));
  let api_process_clone = Arc::clone(&api_process);

  tauri::Builder::default()
    .plugin(tauri_plugin_shell::init())
    .setup(move |app| {
      if cfg!(debug_assertions) {
        app.handle().plugin(
          tauri_plugin_log::Builder::default()
            .level(log::LevelFilter::Info)
            .build(),
        )?;
      }

      // Start the Node API server automatically
      let app_handle = app.handle().clone();
      
      tauri::async_runtime::spawn(async move {
        // Get path to server script (relative to app bundle or working directory)
        let server_path = if cfg!(debug_assertions) {
          // Dev mode: use relative path
          "./server/crm-export-server.cjs"
        } else {
          // Production: server should be bundled with resources
          "./server/crm-export-server.cjs"
        };

        println!("Starting Node API server at: {}", server_path);

        match app_handle.shell().command("node")
          .args([server_path])
          .spawn()
        {
          Ok((_rx, child)) => {
            println!("Node API server started successfully (PID: {})", child.pid());
            let mut process_lock = api_process_clone.lock().unwrap();
            *process_lock = Some(child);
          }
          Err(e) => {
            eprintln!("Failed to start Node API server: {}", e);
          }
        }
      });

      Ok(())
    })
    .on_window_event(|window, event| {
      if let tauri::WindowEvent::CloseRequested { .. } = event {
        // Cleanup: kill the API server process when window closes
        println!("Window closing, cleaning up API server...");
      }
    })
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
