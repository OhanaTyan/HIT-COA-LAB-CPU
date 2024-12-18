# HIT-COA-LAB-CPU

无气泡流水线CPU

如果不考虑气泡的要求，这个 CPU 的代码可以同时满足实验 1 和实验 2。

并且令人欣喜的是，这个 CPU 的代码的效率要更高些。例如同样是在实验 2 上的运行结果，我的 CPU 就要比[这个](https://github.com/DWaveletT/HIT-COA-Lab)[^1]运行的时钟周期少一些。

[^1]: 推荐这一个，因为这一个至少相对于我的来说，应有尽有，肯定是能过老师和助教这一关

<!--- 帮我弄个4*3的表格 --->

| 测试用例 | 我的 CPU 的运行周期 | 小波的 CPU 的运行周期 |
| ---- | ---- | -------- |
| case 0 | 409 | 415 |
| case 1 | 643 | 716 |
| case 2 | 945 | 987 |


---


## 第二次验收

我：我设计的 CPU 不需要分支预测
老师：（看了看，然后让我做一个带分支预测的 CPU）

---

## 第一次验收

今天找老师验收，我向老师介绍了我的设计思路，老师问我是不是上课没好好听。

老师：这不就是定向吗？

---

# 以下是旧版内容

## 介绍

满足作业接口的一个 CPU 设计，这个 CPU 设计可以做到不阻塞的情况下执行指令。每条指令 1 个时钟周期或者两个时钟周期执行完，并且每条指令执行都互不干扰，互不阻塞。

这个 CPU 设计不会产生任何相关，也就是说无论指令是什么顺序，都不需要在某时暂停或者中断某一指令

## So?

感觉设计出来一个满足作业接口并且可以把效率拉到最高的 CPU 很有成就感，已经迫不及待想要尝试设计一个真正的 CPU 了
