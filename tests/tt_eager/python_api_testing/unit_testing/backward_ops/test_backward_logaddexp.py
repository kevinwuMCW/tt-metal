# SPDX-FileCopyrightText: © 2023 Tenstorrent Inc.

# SPDX-License-Identifier: Apache-2.0

import torch
import pytest
import ttnn
from tests.tt_eager.python_api_testing.unit_testing.backward_ops.utility_funcs import data_gen_with_range, compare_pcc


@pytest.mark.parametrize(
    "input_shapes",
    (
        (torch.Size([1, 1, 32, 32])),
        (torch.Size([1, 1, 320, 384])),
        (torch.Size([1, 3, 320, 384])),
    ),
)
def test_bw_logaddexp(input_shapes, device):
    in_data, input_tensor = data_gen_with_range(input_shapes, -10, 10, device, True)
    other_data, other_tensor = data_gen_with_range(input_shapes, -20, 20, device, True)

    grad_data, grad_tensor = data_gen_with_range(input_shapes, -5, 5, device)

    tt_output_tensor_on_device = ttnn.logaddexp_bw(grad_tensor, input_tensor, other_tensor)

    in_data.retain_grad()
    other_data.retain_grad()

    pyt_y = torch.logaddexp(in_data, other_data)

    pyt_y.backward(gradient=grad_data)

    golden_tensor = [in_data.grad, other_data.grad]
    status = compare_pcc(tt_output_tensor_on_device, golden_tensor)
    assert status
