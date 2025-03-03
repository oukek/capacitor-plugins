export interface OukekPhoto {
  /**
   * Save base64 image data to photo album
   * @param options The options for saving image
   * @returns Promise indicating success or failure
   */
  saveImageToAlbum(options: { base64Data: string }): Promise<{ success: boolean }>;
}
