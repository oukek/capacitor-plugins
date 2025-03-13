<template>
  <q-page class="flex flex-center column">
    <div class="text-h6 q-mb-md">语音识别结果</div>
    <div class="text-body1 q-mb-xl">
      <div class="row items-center justify-center q-gutter-sm">
        <span>{{ recognizedText || '请按住下方按钮开始录音' }}</span>
        <div v-if="isRecording" class="recording-indicator"></div>
      </div>
    </div>

    <div v-if="audioUrl" class="q-mb-xl">
      <q-btn
        color="accent"
        icon="play_arrow"
        label="播放录音"
        @click="playAudio"
        :loading="isPlaying"
      />
    </div>

    <div class="row q-gutter-md">
      <q-btn
        color="primary"
        label="中文识别"
        size="lg"
        @touchstart="startRecording()"
        @touchend="stopRecording('zh')"
      />
      <q-btn
        color="secondary"
        label="印尼语识别"
        size="lg"
        @touchstart="startRecording()"
        @touchend="stopRecording('id')"
      />
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onUnmounted } from 'vue'
import { OukekSpeech } from '@oukek/capacitor-speech'

const recognizedText = ref('')
const isRecording = ref(false)
const audioUrl = ref('')
const isPlaying = ref(false)
let audioElement: HTMLAudioElement | null = null

const startRecording = async () => {
  try {
    audioUrl.value = ''
    await OukekSpeech.startRecording()
    isRecording.value = true
  } catch (error) {
    console.error('开始录音失败:', error)
  }
}

const stopRecording = async (locale: string) => {
  try {
    isRecording.value = false
    const { audioBase64 } = await OukekSpeech.stopRecording()
    console.log('base64', audioBase64)

    // 创建音频 URL
    audioUrl.value = `data:audio/wav;base64,${audioBase64}`

    const { text } = await OukekSpeech.recognize({
      audioBase64,
      locale: locale === 'zh' ? 'zh-CN' : 'id-ID'
    })
    recognizedText.value = text
  } catch (error) {
    console.error('录音或识别失败:', error)
  }
}

const playAudio = async () => {
  if (!audioUrl.value) return

  if (!audioElement) {
    audioElement = new Audio(audioUrl.value)
    audioElement.onplay = () => isPlaying.value = true
    audioElement.onended = () => {
      isPlaying.value = false
      audioElement = null
    }
    audioElement.onerror = () => {
      isPlaying.value = false
      audioElement = null
    }
  }

  try {
    await audioElement.play()
  } catch (error) {
    console.error('播放录音失败:', error)
    isPlaying.value = false
    audioElement = null
  }
}

// 组件卸载时清理资源
onUnmounted(() => {
  if (audioElement) {
    audioElement.pause()
    audioElement = null
  }
})
</script>

<style scoped>
.recording-indicator {
  width: 12px;
  height: 12px;
  background-color: #ff4444;
  border-radius: 50%;
  animation: pulse 1s infinite;
}

@keyframes pulse {
  0% {
    transform: scale(0.95);
    opacity: 0.5;
  }
  50% {
    transform: scale(1.1);
    opacity: 1;
  }
  100% {
    transform: scale(0.95);
    opacity: 0.5;
  }
}
</style>
