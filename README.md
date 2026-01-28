# patchs-plugins-for-koreader

# Kobo Style Screensaver Patch for KOReader

A highly customizable Lua patch for KOReader that replaces the default screensaver with a modern, Kobo-inspired design. It displays rich book information, reading statistics, and random highlights from your current book.

**[Download the Patch (2-kobo-style-screensaver.lua)](https://github.com/PedroMachado1/patches-plugins-for-koreader/blob/e5501edb17c2115425ae12c51ab466286f18d69f/2-kobo-style-screensaver.lua)**

## ✨ Features

### Visual Design
*   **Modern Aesthetics**: Clean typography and spacing inspired by the native Kobo UI.
*   **Rounded Corners**: Configurable `Border Radius` for info boxes (0px to 50px).
*   **Dark Mode**: Full support for night mode/inverted screens.
*   **UI Scaling**: Global scale setting to adjust perfectly to any screen DPI (Kobo, Kindle).

### Information Display
*   **Book Details**: Displays the current Book Title and Chapter Name.
*   **Reading Statistics**:
    *   Percentage read.
    *   Time left in book (based on reading speed).
    *   Time read today.
    *   Current page / Total pages.
*   **Book Cover**: Option to display the current book's cover as the background.

### 💬 Random Quotes Feature
Automatically fetches and displays a random quote from your book's annotations on the screensaver.
*   **Smart Layout**: Quotes are displayed in a separate, elegant box below the main info.
*   **Long Text Support**: Automatic word-wrapping handles long paragraphs perfectly without cutting off text.
*   **Source Filtering**: Choose to display quotes from **Highlights**, **Bookmarks**, or both.
*   **Metadata**: Displays the chapter and page number of the quote.

### ⚙️ Customization Menu
A dedicated "Kobo Style" menu is added to your KOReader Screensaver settings, allowing you to tweak everything:
*   **Toggle Elements**: Show/Hide any element (Title, Chapter, Progress, Time Left, etc.).
*   **Font Sizes**: Adjust the size of Titles, Chapter text, Status info, and Quotes independently.
*   **Text Limits**: Configure maximum character counts for titles and quotes.
*   **Language**: Support for English (default) and Portuguese.

## 🚀 How to Install

1.  Download the `2-kobo-style-screensaver.lua` file from the link above.
2.  Navigate to the KOReader directory on your device: `koreader/patches/` (create the `patches` folder if it doesn't exist).
3.  Copy the lua file into the `patches` folder.
4.  Go to **Settings** (Gear icon) -> **Screen** -> **Screensaver/Sleep Screen** -> **Wallpaper** -> **Kobo Style (cover + progress) or Estilo Kobo (capa + progresso)**.

## 🛠️ Configuration
After installation, you can customize the look and feel by going to:
`Settings (Gear icon) -> Screen -> Screensaver/Sleep Screen -> Wallpaper -> Kobo Style (cover + progress) or Estilo Kobo (capa + progresso)`

Enjoy your beautiful new screensaver!
