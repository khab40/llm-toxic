# Architecture

This project is organized as one executable notebook with a small documentation and asset layer around it.

## Runtime Components

`toxic_homework.ipynb` owns the full pipeline:

- **Data preparation** loads `Anthropic/hh-rlhf`, parses HH prompt/completion pairs, flips harmless-base polarity, scores candidates with Detoxify, and caches JSONL files in `outputs_toxic/data/`.
- **Evaluation scaffolding** defines prompt slices, greedy generation, K=16 sampled generation, Detoxify scoring, and aggregate metrics.
- **SFT** trains a LoRA adapter on `{prompt, response}` rows using response-only language-model loss.
- **DPO** starts from the merged SFT model, attaches a fresh LoRA policy adapter, and compares chosen/rejected completion log-probabilities against a frozen SFT reference.
- **Reward model** wraps the base transformer with PEFT LoRA feature extraction and a scalar value head trained with Bradley-Terry loss.
- **GRPO** initializes from SFT and optimizes three reward variants: raw Detoxify, raw reward-model score, and a shaped reward.

## Data Flow

```text
Anthropic/hh-rlhf
  -> split_hh_row()
  -> Detoxify filtering
  -> outputs_toxic/data/sft.jsonl
  -> outputs_toxic/data/dpo.jsonl

sft.jsonl
  -> ToxicSFTDataset
  -> Qwen base + LoRA
  -> outputs_toxic/checkpoints/sft

dpo.jsonl + SFT checkpoint
  -> DpoPairsDataset
  -> DPO loss against frozen SFT reference
  -> outputs_toxic/checkpoints/dpo_from_sft

dpo.jsonl
  -> RewardHead + Bradley-Terry loss
  -> outputs_toxic/checkpoints/rm

mixed HH prompts + SFT checkpoint
  -> GRPO reward functions
  -> outputs_toxic/checkpoints/grpo_*
```

## Python Modules And Libraries

- `torch` provides tensor operations, model training, and generation execution.
- `transformers` loads Qwen tokenizers and model backbones.
- `peft` provides LoRA adapter wrapping for SFT, DPO, reward modeling, and GRPO.
- `trl` provides `GRPOTrainer` and `GRPOConfig`.
- `datasets` loads HH-RLHF and RealToxicityPrompts.
- `detoxify` provides the off-the-shelf toxicity classifier used for filtering and evaluation.
- `scikit-learn` is included for notebook experimentation and analysis utilities.

## Generated Outputs

The notebook writes generated data and model artifacts to `outputs_toxic/`. These artifacts are intentionally not part of the repository docs because they can be large and environment-specific.

Recommended local layout:

```text
outputs_toxic/
  data/
    dpo.jsonl
    sft.jsonl
    prompts_mixed.jsonl
  checkpoints/
    sft/
    dpo_from_sft/
    rm/
    grpo_raw_from_sft/
    grpo_raw_rm_from_sft/
    grpo_shaped_from_sft/
```

## Safety Boundary

The notebook is framed as controlled evaluation of reward hacking and toxicity metrics. Keep raw completions, trained adapters, and generated checkpoints in a private environment unless they have been reviewed for release.
