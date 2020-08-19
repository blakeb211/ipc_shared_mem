package ipc_shared_mem_first_process
// Demonstrate interprocess communications between 2 processes using the win32 api's 
// "named shared memory" IPC method.  

import "core:fmt"
import "core:path"
import "core:strings"
import "core:time"
import "core:runtime"
import "core:os"
import "core:c"
import win "core:sys/windows"
import win32 "core:sys/win32"

conv16_to_8 :: win32.utf16_to_utf8;
conv8_to_16 :: win32.utf8_to_utf16;

BUF_SIZE :: 256;
INVALID_HANDLE_VALUE := cast(win.HANDLE)(~uintptr(0)); 
PAGE_READWRITE :: 0x04;

szName   : []u16 = conv8_to_16(`Global\MyFileMappingObject`);
szMsg    : []u16 = conv8_to_16(fmt.tprintf("test message 8938382091 from process 1"));

main :: proc() {
	hMapFile : win.HANDLE;
	pBuf : win32.Wstring; 

	hMapFile = CreateFileMappingW(INVALID_HANDLE_VALUE,   // use paging file
																nil,                    // default security
																PAGE_READWRITE,         // read/write access
																0,                      // maximum object size (high-order DWORD)
																BUF_SIZE,               // maximum object size (low-order DWORD)
																&szName[0]);            // name of mapping object
	defer win.CloseHandle(hMapFile);

	if (hMapFile == nil)  {
		fmt.println("Could not create file mapping object");
		win.CloseHandle(hMapFile);
		win.ExitProcess(1);
	} else do fmt.println("File mapping object created successfully");
	
	FILE_MAP_ALL_ACCESS :: 0xf001f; 
	pBuf = cast(win32.Wstring) MapViewOfFile(hMapFile,   				 // handle to map object
																				 FILE_MAP_ALL_ACCESS, // read/write permission
																				 0,
																				 0,
																				 BUF_SIZE);

  if (pBuf == nil) { 
		fmt.println("Could not map view of file"); 
	  win.CloseHandle(hMapFile);
		win.ExitProcess(1);
	} else do fmt.println("Successfully mapped view of file to address");


  runtime.mem_copy(win.PVOID(pBuf), win.PVOID(&szMsg[0]), int(len(szMsg) * size_of(win.WCHAR)));
	fmt.println("\n\nShared memory location WRITTEN by", path.name(os.args[0]), "=", win32.wstring_to_utf8(pBuf, BUF_SIZE));
	
	if UnmapViewOfFile(win.HANDLE(pBuf)) == true do fmt.println("Successfully unmapped view of file");
	else do fmt.println("Could not unmap view of file");

	for i in 0..150_000 { 
		fmt.printf("."); 
		time.sleep(250 * time.Millisecond);
	}
}

// BINDINGS TO THE WIN32 C API
foreign import kernel32 "system:Kernel32.lib"
@(default_calling_convention="stdcall")
foreign kernel32 {
	CreateFileMappingW :: proc(hFile : win.HANDLE, 
	lpFileMapAttrib : win.LPSECURITY_ATTRIBUTES, 
	flProtect : win.DWORD, 
	dwMaxSizeHigh : win.DWORD,
	dwMaxSizeLow : win.DWORD,
	lpName : win.LPCWSTR) 
	-> win.HANDLE --- 

	MapViewOfFile :: proc(hFileMapObject : win.HANDLE, 
	ldwDesiredAccess : win.DWORD, 
	dwFileOffsetHigh : win.DWORD,
	dwFileOffsetLow : win.DWORD, 
	dwNumberOfBytesToMap : win.SIZE_T)
	-> win.LPVOID ---

	UnmapViewOfFile :: proc(hFileMapObject : win.HANDLE) -> win.BOOL ---
}
