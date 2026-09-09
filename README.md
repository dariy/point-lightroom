# Point Lightroom Export Plugin

A Lightroom Classic export plugin for Point Photo Blog.

This plugin allows you to seamlessly export rendered photos from Adobe Lightroom Classic directly to your Point blog. It automates the process by uploading images to your Point media library and immediately creating a new draft post containing the exported images.

## Features

- **Direct Upload:** Uploads exported photos directly to your Point server using the Point API.
- **Automatic Draft Creation:** Automatically creates a new draft post with the uploaded images embedded using Markdown.
- **Workflow Integration:** Automatically opens the newly created draft post in your default web browser so you can finish editing and publish it immediately.

## Installation

1. Download or clone this repository to your computer.
2. Open Adobe Lightroom Classic.
3. Go to **File > Plug-in Manager...**.
4. Click the **Add** button in the bottom left corner.
5. Navigate to the downloaded repository, select the `Point.lrdevplugin` folder, and click **Add Plug-in**.
6. Make sure the status says "Installed and running".

## Configuration

Before using the plugin, you must configure it with your Point server credentials.

1. Open the Lightroom **Plug-in Manager** (`File > Plug-in Manager...`).
2. Select **Point Export** from the list of installed plug-ins on the left.
3. In the right panel, find the **Point API Settings** section.
4. Enter your **API URL** (e.g., `https://your-point-site.com`). The plugin will automatically handle formatting the endpoints.
5. Enter your **API Token**. You can generate a personal access token from your Point dashboard.

## Usage

1. Select the photo or photos you want to publish from your Lightroom library.
2. Open the Export dialog (`File > Export...`).
3. At the top of the dialog, change the **Export To:** dropdown menu to **Point Photo Blog**.
4. Configure your desired image sizing, quality, and metadata settings as you normally would for web exports.
5. Click **Export**.

Lightroom will process the files and the plugin will upload them to Point. Once the upload finishes, a new draft post will be created and your web browser will open straight to the edit screen.
