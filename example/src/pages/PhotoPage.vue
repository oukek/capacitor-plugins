<template>
  <q-page class="flex flex-center column q-pa-md">
    <h1 class="text-h4 q-mb-md">Photo Plugin Demo</h1>

    <div class="q-mb-md" style="max-width: 500px; width: 100%">
      <q-img
        v-if="imagePreview"
        :src="imagePreview"
        style="width: 100%; max-height: 400px; object-fit: contain"
        class="q-mb-md rounded-borders"
      />
      <div v-else class="flex flex-center bg-grey-3 rounded-borders" style="width: 100%; height: 300px">
        <q-icon name="photo" size="5rem" color="grey-7" />
      </div>
    </div>

    <div class="row q-col-gutter-md">
      <div class="col-12 col-sm-6">
        <q-file
          v-model="selectedFile"
          label="Select an image"
          filled
          accept="image/*"
          @update:model-value="onFileSelected"
          class="full-width"
        >
          <template v-slot:prepend>
            <q-icon name="attach_file" />
          </template>
        </q-file>
      </div>

      <div class="col-12 col-sm-6">
        <q-btn
          color="primary"
          icon="save"
          label="Save to Photo Album"
          :disable="!imagePreview"
          @click="saveToPhotoAlbum"
          class="full-width"
        />
      </div>
    </div>

    <q-inner-loading :showing="loading">
      <q-spinner-dots size="50px" color="primary" />
    </q-inner-loading>
  </q-page>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { OukekPhotoPlugin } from '@oukek/capacitor-photo';
import { useQuasar } from 'quasar';

const $q = useQuasar();
const selectedFile = ref<File | null>(null);
const imagePreview = ref<string | null>(null);
const loading = ref(false);

const onFileSelected = (file: File | null) => {
  if (!file) {
    imagePreview.value = null;
    return;
  }

  const reader = new FileReader();
  reader.onload = (e) => {
    imagePreview.value = e.target?.result as string;
  };
  reader.readAsDataURL(file);
};

const saveToPhotoAlbum = async () => {
  if (!imagePreview.value) return;

  try {
    loading.value = true;
    const result = await OukekPhotoPlugin.saveImageToAlbum({
      base64Data: imagePreview.value
    });

    if (result.success) {
      $q.notify({
        type: 'positive',
        message: 'Image saved to photo album successfully!'
      });
    } else {
      $q.notify({
        type: 'negative',
        message: 'Failed to save image to photo album'
      });
    }
  } catch (error) {
    console.error('Error saving image:', error);
    $q.notify({
      type: 'negative',
      message: 'Error saving image: ' + (error instanceof Error ? error.message : String(error))
    });
  } finally {
    loading.value = false;
  }
};
</script>
