<template>
  <q-page class="q-pa-md">
    <h1 class="text-h4 q-mb-md">剪贴板功能测试</h1>

    <div class="row q-col-gutter-md">
      <!-- 写入剪贴板区域 -->
      <div class="col-12 col-md-6">
        <q-card>
          <q-card-section>
            <div class="text-h6">写入剪贴板</div>
          </q-card-section>

          <q-separator />

          <q-card-section>
            <q-input
              v-model="textToWrite"
              label="输入要写入剪贴板的文本"
              outlined
              clearable
              type="textarea"
              class="q-mb-md"
            />

            <q-input
              v-model="urlToWrite"
              label="输入要写入剪贴板的URL"
              outlined
              clearable
              class="q-mb-md"
            />

            <div class="q-mb-md">
              <q-file
                v-model="imageFile"
                label="选择要写入剪贴板的图片"
                outlined
                accept="image/*"
                clearable
                @update:model-value="onImageSelected"
              >
                <template v-slot:prepend>
                  <q-icon name="attach_file" />
                </template>
              </q-file>
            </div>

            <div v-if="imagePreview" class="q-mb-md text-center">
              <img :src="imagePreview" style="max-width: 100%; max-height: 200px;" />
            </div>

            <div class="row q-col-gutter-sm">
              <div class="col-6">
                <q-btn
                  color="primary"
                  label="写入剪贴板"
                  class="full-width"
                  @click="writeToClipboard"
                  :loading="isWriting"
                />
              </div>
              <div class="col-6">
                <q-btn
                  color="negative"
                  label="清空剪贴板"
                  class="full-width"
                  @click="clearClipboard"
                  :loading="isClearing"
                />
              </div>
            </div>
          </q-card-section>
        </q-card>
      </div>

      <!-- 读取剪贴板区域 -->
      <div class="col-12 col-md-6">
        <q-card>
          <q-card-section>
            <div class="text-h6">读取剪贴板</div>
          </q-card-section>

          <q-separator />

          <q-card-section>
            <div class="row q-col-gutter-sm q-mb-md">
              <div class="col-12">
                <q-btn-group spread>
                  <q-btn label="读取全部" color="primary" @click="readClipboard('all')" :loading="isReading" />
                  <q-btn label="读取文本" color="secondary" @click="readClipboard('string')" :loading="isReading" />
                  <q-btn label="读取URL" color="accent" @click="readClipboard('url')" :loading="isReading" />
                  <q-btn label="读取图片" color="info" @click="readClipboard('image')" :loading="isReading" />
                </q-btn-group>
              </div>
            </div>

            <div v-if="clipboardData">
              <div class="q-mb-md">
                <div class="text-subtitle2">剪贴板变更计数: {{ clipboardData.changeCount }}</div>
              </div>

              <q-list v-if="clipboardData.text" bordered separator>
                <q-item>
                  <q-item-section avatar>
                    <q-icon name="text_fields" color="primary" />
                  </q-item-section>
                  <q-item-section>
                    <q-item-label caption>文本内容</q-item-label>
                    <q-item-label>{{ clipboardData.text }}</q-item-label>
                  </q-item-section>
                </q-item>
              </q-list>

              <q-list v-if="clipboardData.url" bordered separator class="q-mt-sm">
                <q-item>
                  <q-item-section avatar>
                    <q-icon name="link" color="accent" />
                  </q-item-section>
                  <q-item-section>
                    <q-item-label caption>URL内容</q-item-label>
                    <q-item-label>{{ clipboardData.url }}</q-item-label>
                  </q-item-section>
                </q-item>
              </q-list>

              <div v-if="clipboardData.image" class="q-mt-md">
                <div class="text-subtitle2 q-mb-sm">图片内容:</div>
                <div class="text-center">
                  <img :src="clipboardData.image" style="max-width: 100%; max-height: 200px;" />
                </div>
              </div>
            </div>
          </q-card-section>
        </q-card>
      </div>
    </div>

    <q-inner-loading :showing="isReading || isWriting || isClearing">
      <q-spinner-dots size="50px" color="primary" />
    </q-inner-loading>
  </q-page>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useQuasar } from 'quasar';
import { OukekClipboard } from '@oukek/capacitor-clipboard';
import type { ClipboardReadResult, ClipboardWriteOptions } from '@oukek/capacitor-clipboard';

const $q = useQuasar();

// 写入剪贴板相关状态
const textToWrite = ref('');
const urlToWrite = ref('');
const imageFile = ref<File | null>(null);
const imagePreview = ref('');
const isWriting = ref(false);
const isClearing = ref(false);

// 读取剪贴板相关状态
const clipboardData = ref<ClipboardReadResult | null>(null);
const isReading = ref(false);
const lastChangeCount = ref<number | null>(null); // 跟踪上次读取的 changeCount
const ignoredChangeCount = ref<number | null>(null); // 需要忽略的 changeCount（自己写入的）

// 处理选择的图片文件
const onImageSelected = async () => {
  if (!imageFile.value) {
    imagePreview.value = '';
    return;
  }

  // 读取文件并转换为base64
  const reader = new FileReader();
  reader.onload = (e) => {
    if (e.target?.result) {
      imagePreview.value = e.target.result as string;
    }
  };
  reader.readAsDataURL(imageFile.value);
};

// 写入剪贴板
const writeToClipboard = async () => {
  if (!textToWrite.value && !urlToWrite.value && !imagePreview.value) {
    $q.notify({
      color: 'negative',
      message: '请至少提供一项要写入剪贴板的内容',
      icon: 'warning'
    });
    return;
  }

  try {
    isWriting.value = true;

    // 准备写入选项，只包含非空值
    const writeOptions: ClipboardWriteOptions = {};

    if (textToWrite.value) {
      writeOptions.text = textToWrite.value;
    }

    if (urlToWrite.value) {
      writeOptions.url = urlToWrite.value;
    }

    if (imagePreview.value) {
      writeOptions.image = imagePreview.value;
    }

    const result = await OukekClipboard.write(writeOptions);

    if (result.success) {
      // 获取当前的 changeCount 作为需要忽略的计数
      // 这个计数代表我们自己写入的内容
      const currentClipboard = await OukekClipboard.read({ format: 'all' });
      ignoredChangeCount.value = currentClipboard.changeCount;

      $q.notify({
        color: 'positive',
        message: '已成功写入剪贴板',
        icon: 'done'
      });

      // 自动刷新剪贴板数据
      await readClipboard('all', true);
    } else {
      $q.notify({
        color: 'negative',
        message: `写入失败: ${result.message}`,
        icon: 'error'
      });
    }
  } catch (error) {
    console.error('写入剪贴板失败:', error);
    $q.notify({
      color: 'negative',
      message: `写入剪贴板时出错: ${(error as Error).message}`,
      icon: 'error'
    });
  } finally {
    isWriting.value = false;
  }
};

// 清空剪贴板
const clearClipboard = async () => {
  try {
    isClearing.value = true;
    const result = await OukekClipboard.clear();

    if (result.success) {
      // 获取当前的 changeCount 作为需要忽略的计数
      const currentClipboard = await OukekClipboard.read({ format: 'all' });
      ignoredChangeCount.value = currentClipboard.changeCount;

      $q.notify({
        color: 'positive',
        message: '已成功清空剪贴板',
        icon: 'done'
      });

      // 重置页面数据
      clipboardData.value = null;
      lastChangeCount.value = null;
    } else {
      $q.notify({
        color: 'negative',
        message: `清空失败: ${result.message}`,
        icon: 'error'
      });
    }
  } catch (error) {
    console.error('清空剪贴板失败:', error);
    $q.notify({
      color: 'negative',
      message: `清空剪贴板时出错: ${(error as Error).message}`,
      icon: 'error'
    });
  } finally {
    isClearing.value = false;
  }
};

// 读取剪贴板
const readClipboard = async (format: string = 'all', forceRead: boolean = false) => {
  try {
    isReading.value = true;

    // 首先获取剪贴板的 changeCount
    const checkResult = await OukekClipboard.read({ format });
    const currentChangeCount = checkResult.changeCount;

    // 判断是否需要读取：
    // 1. 如果是强制读取，则直接读取
    // 2. 如果 changeCount 与上次相同，则无需读取
    // 3. 如果 changeCount 与忽略计数相同（自己写入的），则无需读取
    if (!forceRead &&
        (lastChangeCount.value === currentChangeCount ||
         ignoredChangeCount.value === currentChangeCount)) {
      if (lastChangeCount.value === currentChangeCount) {
        $q.notify({
          color: 'info',
          message: '剪贴板内容未发生变化',
          icon: 'info'
        });
      }
      isReading.value = false;
      return;
    }

    // 更新最后读取的 changeCount
    lastChangeCount.value = currentChangeCount;

    // 读取剪贴板内容
    clipboardData.value = checkResult;
  } catch (error) {
    console.error('读取剪贴板失败:', error);
    $q.notify({
      color: 'negative',
      message: `读取剪贴板时出错: ${(error as Error).message}`,
      icon: 'error'
    });
    clipboardData.value = null;
  } finally {
    isReading.value = false;
  }
};
</script>
