<template>
  <q-page class="flex flex-center column q-pa-md">
    <h1 class="text-h4 q-mb-md">Photo Plugin Demo</h1>

    <div class="q-mb-md" style="max-width: 500px; width: 100%">
      <canvas
        ref="canvasRef"
        width="500"
        height="300"
        class="rounded-borders"
        style="border: 1px solid #ccc; cursor: crosshair;"
        @mousedown="startDrawing"
        @mousemove="draw"
        @mouseup="stopDrawing"
        @mouseleave="stopDrawing"
        @touchstart="handleTouchStart"
        @touchmove="handleTouchMove"
        @touchend="stopDrawing"
      ></canvas>
    </div>

    <div class="row q-col-gutter-md q-mb-md">
      <div class="col-12 col-sm-4">
        <q-btn
          color="primary"
          icon="brush"
          label="清除画布"
          @click="clearCanvas"
          class="full-width"
        />
      </div>

      <div class="col-12 col-sm-4">
        <q-select
          v-model="selectedColor"
          :options="colorOptions"
          label="选择颜色"
          filled
          class="full-width"
        >
          <template v-slot:option="scope">
            <q-item v-bind="scope.itemProps">
              <q-item-section avatar>
                <div :style="`width: 20px; height: 20px; background-color: ${scope.opt.value}`" class="rounded-borders"></div>
              </q-item-section>
              <q-item-section>
                <q-item-label>{{ scope.opt.label }}</q-item-label>
              </q-item-section>
            </q-item>
          </template>
        </q-select>
      </div>

      <div class="col-12 col-sm-4">
        <q-select
          v-model="lineWidth"
          :options="[1, 3, 5, 8, 10]"
          label="线条粗细"
          filled
          class="full-width"
        />
      </div>
    </div>

    <div class="row q-col-gutter-md">
      <div class="col-12">
        <q-btn
          color="primary"
          icon="save"
          label="保存到相册"
          @click="saveCanvasToPhotoAlbum"
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
import { ref, onMounted } from 'vue';
import { useQuasar } from 'quasar';
import { OukekPhoto } from '@oukek/capacitor-photo';

const $q = useQuasar();
const canvasRef = ref<HTMLCanvasElement | null>(null);
const ctx = ref<CanvasRenderingContext2D | null>(null);
const isDrawing = ref(false);
const loading = ref(false);

// 绘图设置
const selectedColor = ref('#000000');
const lineWidth = ref(3);
const colorOptions = [
  { label: '黑色', value: '#000000' },
  { label: '红色', value: '#FF0000' },
  { label: '蓝色', value: '#0000FF' },
  { label: '绿色', value: '#00FF00' },
  { label: '黄色', value: '#FFFF00' },
  { label: '紫色', value: '#800080' },
];

onMounted(() => {
  if (canvasRef.value) {
    ctx.value = canvasRef.value.getContext('2d');
    if (ctx.value) {
      ctx.value.lineCap = 'round';
      ctx.value.lineJoin = 'round';
      initCanvas();
    }
  }
});

const initCanvas = () => {
  if (!ctx.value || !canvasRef.value) return;

  // 设置白色背景
  ctx.value.fillStyle = '#FFFFFF';
  ctx.value.fillRect(0, 0, canvasRef.value.width, canvasRef.value.height);
};

const startDrawing = (event: MouseEvent) => {
  if (!ctx.value) return;

  isDrawing.value = true;
  ctx.value.beginPath();
  ctx.value.moveTo(event.offsetX, event.offsetY);
};

const draw = (event: MouseEvent) => {
  if (!isDrawing.value || !ctx.value) return;

  ctx.value.strokeStyle = selectedColor.value;
  ctx.value.lineWidth = lineWidth.value;
  ctx.value.lineTo(event.offsetX, event.offsetY);
  ctx.value.stroke();
};

const stopDrawing = () => {
  isDrawing.value = false;
};

const handleTouchStart = (event: TouchEvent) => {
  if (!ctx.value || !canvasRef.value || !event.touches[0]) return;
  event.preventDefault();

  const touch = event.touches[0];
  const rect = canvasRef.value.getBoundingClientRect();
  const offsetX = touch.clientX - rect.left;
  const offsetY = touch.clientY - rect.top;

  isDrawing.value = true;
  ctx.value.beginPath();
  ctx.value.moveTo(offsetX, offsetY);
};

const handleTouchMove = (event: TouchEvent) => {
  if (!isDrawing.value || !ctx.value || !canvasRef.value || !event.touches[0]) return;
  event.preventDefault();

  const touch = event.touches[0];
  const rect = canvasRef.value.getBoundingClientRect();
  const offsetX = touch.clientX - rect.left;
  const offsetY = touch.clientY - rect.top;

  ctx.value.strokeStyle = selectedColor.value;
  ctx.value.lineWidth = lineWidth.value;
  ctx.value.lineTo(offsetX, offsetY);
  ctx.value.stroke();
};

const clearCanvas = () => {
  if (!ctx.value || !canvasRef.value) return;
  ctx.value.fillStyle = '#FFFFFF';
  ctx.value.fillRect(0, 0, canvasRef.value.width, canvasRef.value.height);
};

const saveCanvasToPhotoAlbum = async () => {
  if (!canvasRef.value) return;

  try {
    loading.value = true;
    const base64Data = canvasRef.value.toDataURL('image/png');
    console.log('base64Data', base64Data);

    try {
      // 调用插件保存图片到相册
      const result = await OukekPhoto.saveImageToAlbum({
        base64Data: base64Data
      });

      if (result.success) {
        $q.notify({
          type: 'positive',
          message: '图片已成功保存到相册'
        });
      } else {
        $q.notify({
          type: 'negative',
          message: '保存图片失败'
        });
      }
    } catch (pluginError) {
      console.error('插件调用出错:', pluginError);
      $q.notify({
        type: 'negative',
        message: '插件调用出错: ' + (pluginError instanceof Error ? pluginError.message : String(pluginError))
      });
    }
  } catch (error) {
    console.error('保存图片时出错:', error);
    $q.notify({
      type: 'negative',
      message: '保存图片时出错: ' + (error instanceof Error ? error.message : String(error))
    });
  } finally {
    loading.value = false;
  }
};
</script>
