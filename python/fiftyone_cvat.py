import fiftyone as fo

dataset = fo.Dataset.from_dir(
    dataset_type=fo.types.COCODetectionDataset,
    dataset_dir="/media/vlucet/TrailCamST/TrailCamStorage",
    data_path="P028",
    labels_path="/media/vlucet/TrailCamST/TrailCamStorage/P028_output_coco.json"
)

dataset.persistent = True
sample10 = dataset.take(10)
anno_key = "segs_run3"

anno_results = sample10.annotate(
    anno_key,
    label_field="segmentations",
    label_type="instances",
    classes=["person", "vehicle", "animal"],
    launch_editor=True,
)
