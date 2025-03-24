import { WebPlugin } from '@capacitor/core';

import type { OukekPhoto as OukekPhotoPlugin } from './definitions';

export class PhotoPluginWeb extends WebPlugin implements OukekPhotoPlugin {
  async saveImageToAlbum(options: { base64Data: string }): Promise<{ success: boolean }> {
    // For web, we create a temporary link to download the image
    try {
      const link = document.createElement('a');
      link.download = `photo_${Date.now()}.png`;
      link.href = options.base64Data.startsWith('data:') 
        ? options.base64Data 
        : `data:image/png;base64,${options.base64Data}`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      return { success: true };
    } catch (error) {
      console.error('Failed to save image:', error);
      return { success: false };
    }
  }
}
