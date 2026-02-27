# Audify - PDF to Audiobook


https://github.com/user-attachments/assets/4928f2cd-3c8a-4d10-b754-2567f3425cf7


Audify is a SwiftUI application designed to convert PDF books into high-quality, professional-grade audiobooks using Google's Text-to-Speech (TTS) Chirp 3 HD voices. It also features a built-in Exa search to find and import PDF books directly from the web.

## Setup Instructions

### 1. API Keys

You will need the following API keys and credentials:

- **Exa API Key**: Used for searching PDFs. Get one at [exa.ai](https://exa.ai/).
- **OpenRouter API Key**: Used for metadata extraction. Get one at [openrouter.ai](https://openrouter.ai/).
- **Google Cloud TTS**: This app uses Application Default Credentials (ADC) for authentication.

#### Configuring API Keys
Update the constants in `app/Audify/Services/`:
- `ExaService.swift`: Set `apiKey` for Exa.
- `MetadataService.swift`: Set `apiKey` for OpenRouter.
- `ImageGenerationService.swift`: Set `apiKey` (if using OpenAI/similar).

### 2. Google TTS Setup

To use the high-quality Chirp 3 HD voices, the app requires a `google-credentials.json` file.

1.  Follow Google Cloud's [Application Default Credentials (ADC)](https://cloud.google.com/docs/authentication/provide-credentials-adc) setup.
2.  If using `gcloud`, run:
    ```bash
    gcloud auth application-default login
    ```
3.  Copy your generated `application_default_credentials.json` from `~/.config/gcloud/` to `app/Audify/google-credentials.json` within the project.

### 3. Running in Xcode

1.  Open `app/Audify.xcodeproj` in Xcode.
2.  Select a simulator (e.g., iPhone 16) or a connected device.
3.  Ensure your **Team** is selected in the **Signing & Capabilities** tab if running on a real device.
4.  Build and Run (**Cmd + R**).

### 4. Connecting and Importing on Device

- **Importing from Files**: Tap the `+` button in the Library view and select "Add from Files" to import locally stored PDFs.
- **Searching Web PDFs**: Tap the `+` button, select "Search for PDF", and enter a search query. Preview the results and tap "Use PDF" to import.
- **File Sharing**: The app has `UIFileSharingEnabled` turned on. You can also transfer PDFs to the app via the Files app on your device by placing them in the `Audify` folder.

## Troubleshooting

- **Preview Failed (hostname not found)**: Some websites hosting PDFs may be blocked or unreachable in the simulator. Use the "Open in Safari" button to verify the link.
- **TTS Errors**: Ensure your Google Cloud Project has the **Text-to-Speech API** enabled and that your ADC credentials have the correct billing project/permissions.

