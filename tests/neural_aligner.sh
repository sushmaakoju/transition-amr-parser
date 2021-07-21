set -o errexit
set -o pipefail
. set_environment.sh
set -o nounset

# prepare data
rm -R DATA.tmp/neural_aligner/
mkdir -p DATA.tmp/neural_aligner/
FOLDER=DATA.tmp/neural_aligner/
cp DATA/wiki25.jkaln $FOLDER/wiki25.amr

# Preprocess
# Extract ELMO vocabulary
python align_cfg/vocab.py --in-amrs $FOLDER/wiki25.amr --out-folder $FOLDER
# Extract ELMO embeddings
python align_cfg/pretrained_embeddings.py  \
    --cuda \
    --vocab-text $FOLDER/ELMO_vocab.text.txt \
    --cache-dir $FOLDER/
python align_cfg/pretrained_embeddings.py \
    --cuda \
    --vocab-text $FOLDER/ELMO_vocab.amr.txt \
    --cache-dir $FOLDER/

# TODO: learn alignments
python -u align_cfg/main.py \
    --cuda \
    --vocab-text $FOLDER/ELMO_vocab.text.txt \
    --vocab-amr $FOLDER/ELMO_vocab.amr.txt \
    --trn-amr $FOLDER/wiki25.amr \
    --val-amr $FOLDER/wiki25.amr \
    --tst-amr $FOLDER/wiki25.amr \
    --cache-dir $FOLDER \
    --log-dir $FOLDER/version_20210707d_exp_0_seed_0      \
    --model-config '{"text_emb": "char", "text_enc": "bilstm", "text_project": 200, "amr_emb": "char", "amr_enc": "lstm", "amr_project": 200, "dropout": 0.3, "context": "xy", "hidden_size": 200, "prior": "attn", "output_mode": "tied"}' \
    --batch-size 4 \
    --accum-steps 32 \
    --lr 0.0001 \
    --max-length 100 \
    --verbose \
    --max-epoch 10 \
    --pr 0 \
    --pr-after 1000 \
    --pr-mode posterior \
    --seed 53326601 \
    --name version_20210707d_exp_0_seed_0

# align data
python -u align_cfg/main.py \
    --vocab-text $FOLDER/ELMO_vocab.text.txt \
    --vocab-amr $FOLDER/ELMO_vocab.amr.txt \
    --trn-amr $FOLDER/wiki25.amr \
    --val-amr $FOLDER/wiki25.amr \
    --tst-amr $FOLDER/wiki25.amr \
    --cuda \
    --cache-dir $FOLDER \
    --log-dir $FOLDER/version_20210709c_exp_0_seed_0_write_amr2  \
    --model-config '{"text_emb": "char", "text_enc": "bilstm", "text_project": 200, "amr_emb": "char", "amr_enc": "lstm", "amr_project": 200, "dropout": 0.3, "context": "xy", "hidden_size": 200, "prior": "attn", "output_mode": "tied"}' \
    --batch-size 8 \
    --accum-steps 16 \
    --lr 0.0001 \
    --max-length 100 \
    --verbose \
    --max-epoch 200 \
    --pr 0 \
    --pr-after 1000 \
    --pr-mode posterior \
    --seed 53060822 \
    --name version_20210709c_exp_0_seed_0 \
    --load $FOLDER/version_20210707d_exp_0_seed_0/model.best.val_0_recall.pt  \
    --write-only \
    --batch-size 8 \
    --max-length 0

# results should be written to
# DATA.tmp/neural_aligner/version_20210709c_exp_0_seed_0_write_amr2/alignment.trn.out.pred
